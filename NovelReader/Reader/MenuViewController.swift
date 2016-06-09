//
//  ReaderViewController.swift
//  NovelReader
//
//  Created by kangyonggen on 4/27/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit
import SnapKit

class MenuViewController: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet weak var topBar: UIView!
    @IBOutlet weak var bottomBar: UIView!
    @IBOutlet weak var maskPanel: UIView!
    @IBOutlet weak var chapterTitle: UILabel!
    @IBOutlet weak var brightnessMask: UIView!
    @IBOutlet weak var topSubContainer: UIView!
    @IBOutlet weak var btmSubContainer: UIView!
    @IBOutlet weak var loadingBoardMask: UIImageView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var topActivityIndicatorContainer: UIView!
    @IBOutlet weak var topActivityIndicatorLabel: UILabel!
    @IBOutlet weak var topActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var catalogContainer: UIView!

    @IBAction func onBackBtnClicked(sender: AnyObject) {
    }

    private var size: CGSize {
        return self.view.bounds.size
    }

    private enum DownZone {
        case None
        case Menu
        case Next
        case Prev
    }

    private var readerMgr: ReaderManager!
    private var stylePanelView: StylePanelView!
    private var readerVC: ReaderViewController!
    private var catalogVC: CatalogViewController!
    private var styleFontsListView: StyleFontsPickerView!
    
    private var menuShow: Bool           = false
    private var needReload: Bool         = false
    private var downZone: DownZone       = .None
    private let stylePanelHeight:CGFloat = 190

	override func viewDidLoad() {
        super.viewDidLoad()

        let styleMenuRect = CGRectMake(0, 0, self.view.bounds.width, stylePanelHeight)
        self.stylePanelView = StylePanelView(frame: styleMenuRect).onShowFontsList {
            self.showFontsList()
        }

        self.styleFontsListView = StyleFontsPickerView(frame: styleMenuRect).onFontsChanged { changed, font in
            if changed && Typesetter.Ins.font != font {
                self.hideMenu {
                    let shouldReload = self.needReload
                    self.needReload = false
                    self.topActivityIndicator.startAnimating()
                    self.topActivityIndicatorContainer.hidden = false
                    FontManager.asyncDownloadFont(font) { s, f, p in
                        if s == FontManager.State.Downloading {
                            let l = "Downloading \(font) \(p)%"
                            self.topActivityIndicatorLabel.text = l
                            Utils.Log(l)
                        } else if s.completed {
                            self.topActivityIndicator.stopAnimating()
                            self.topActivityIndicatorContainer.hidden = true
                            if s == FontManager.State.Finish {
                                Typesetter.Ins.font = font
                            } else if shouldReload {
                                self.reloadReader(true)
                            }
                        } else {
                            self.topActivityIndicatorLabel.text = "Querying \(font)"
                        }
                    }
                }
            } else {
                self.hideMenu()
            }
        }
        
        self.btmSubContainer.addSubview(styleFontsListView)
        self.btmSubContainer.addSubview(stylePanelView)

        self.styleFontsListView.hidden      = true
        self.loadingBoardMask.hidden        = !Typesetter.Ins.theme.boardMaskNeeded
        self.topActivityIndicator.transform = CGAffineTransformMakeScale(0.5, 0.5)

        Typesetter.Ins.addListener("MenuListener") { observer, oldValue in
            switch (observer) {
            case .Theme:
                self.hideMenu { self.applyTheme() }
            case .Brightness:
                self.brightnessMask.alpha  = 1 - Typesetter.Ins.brightness
                self.brightnessMask.hidden = Typesetter.Ins.brightness == 1
            case .Font:
                self.reloadReader(false)
            default:
				if let reader = self.readerVC {
					reader.applyFormat()
				}
                self.needReload = true
                break
            }
        }
	}

    override func viewWillAppear(animated: Bool) {
        // Start loading
        self.loadingIndicator.startAnimating()
        
		Utils.asyncTask({ () -> Book? in
			return Book(fullFilePath: NSBundle.mainBundle().pathForResource(BUILD_BOOK, ofType: "txt")!)
		}) { book in
			if let b = book {
				self.readerMgr = ReaderManager(b: b, size: self.view.frame.size)

				self.readerMgr.addListener("MenuTitle", forMonitor: .ChapterChanged) { chapter in
                    // Set top title
					self.chapterTitle.text = chapter.title
                    // Sync catalog list
					self.catalogVC.syncReaderStatus(b, currentChapter: chapter)
				}

				self.readerMgr.asyncLoading({ chapter in
					self.attachReaderView(chapter)
				})
			}
		}

        stylePanelView.snp_makeConstraints { make in
            make.top.equalTo(self.btmSubContainer.snp_top)
            make.left.equalTo(self.btmSubContainer.snp_left)
            make.width.equalTo(self.btmSubContainer.snp_width)
            make.height.equalTo(self.stylePanelHeight)
        }

        styleFontsListView.snp_makeConstraints { make in
            make.top.equalTo(self.btmSubContainer.snp_top)
            make.left.equalTo(self.btmSubContainer.snp_left)
            make.width.equalTo(self.btmSubContainer.snp_width)
            make.height.equalTo(self.stylePanelHeight)
        }

        self.applyTheme()
    }

    override func prefersStatusBarHidden() -> Bool {
        return !menuShow
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }

    private func reloadReader(withBlink: Bool = true) {
        if self.readerMgr != nil {
            self.brightnessMask.userInteractionEnabled = true
            self.loadingIndicator.startAnimating()

            // Async reload
            self.readerMgr.asyncLoading { _ in
                self.readerVC.loadPapers(withBlink)
                self.loadingIndicator.stopAnimating()
                self.brightnessMask.userInteractionEnabled = false
            }
        }
    }
    
    private func applyTheme() {
        self.topBar.tintColor                    = Typesetter.Ins.theme.foregroundColor
        self.bottomBar.tintColor                 = Typesetter.Ins.theme.foregroundColor
        self.view.backgroundColor                = Typesetter.Ins.theme.backgroundColor
        self.brightnessMask.alpha                = 1 - Typesetter.Ins.brightness
        self.brightnessMask.hidden               = Typesetter.Ins.brightness == 1
        self.chapterTitle.textColor              = Typesetter.Ins.theme.foregroundColor
        self.loadingIndicator.color              = Typesetter.Ins.theme.foregroundColor
        self.topBar.backgroundColor              = Typesetter.Ins.theme.menuBackgroundColor
        self.bottomBar.backgroundColor           = Typesetter.Ins.theme.menuBackgroundColor
        self.topActivityIndicator.color          = Typesetter.Ins.theme.foregroundColor.newAlpha(0.5)
        self.topActivityIndicatorLabel.textColor = Typesetter.Ins.theme.foregroundColor.newAlpha(0.5)

		if let rvc = self.readerVC {
			rvc.applyTheme()
		}

        if catalogVC != nil {
            catalogVC.applyTheme()
        }
	}
    
	private func attachReaderView(currChapter: Chapter) {
        chapterTitle.text           = currChapter.title
        readerVC            = ReaderViewController(nibName: "ReaderViewController", bundle: nil)
        readerVC.readerMgr  = self.readerMgr
        readerVC.view.frame = self.view.frame
        readerVC.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.maskTaped(_:))))

        loadingIndicator.stopAnimating()
		addChildViewController(self.readerVC)
		view.addSubview(self.readerVC.view)
		view.sendSubviewToBack(self.readerVC.view)

        if !loadingBoardMask.hidden {
            UIView.animateWithDuration(R.Dimens.AnimInterval.Normal, animations: {
                self.loadingBoardMask.alpha  = 0
            }) { end in
                self.loadingBoardMask.hidden = true
                self.loadingBoardMask.alpha  = 1
            }
        }

		catalogVC = CatalogViewController(nibName: "CatalogViewController", bundle: nil)
		catalogVC.syncReaderStatus(self.readerMgr.book, currentChapter: self.readerMgr.currChapter)
		catalogVC.view.frame = catalogContainer.frame
		catalogVC.onDismiss { selected, bm in
			self.dismissCatalog()

			if selected {
				// Jump to selected chapter(bm)
				Utils.Log("Jump to \(bm)")
			}
		}
        
		catalogContainer.onClick { v in
			if self.menuShow {
				self.hideMenu()
			} else {
				self.dismissCatalog()
			}
		}

        addChildViewController(catalogVC)
        catalogContainer.addSubview(catalogVC.view)

        catalogVC.view.snp_makeConstraints { make in
            make.top.equalTo(self.catalogContainer.snp_top)
            make.left.equalTo(self.catalogContainer.snp_left)
            make.width.equalTo(self.size.width * 5 / 6)
            make.height.equalTo(self.catalogContainer.snp_height)
        }
	}

    func maskTaped(recognizer: UITapGestureRecognizer) {
        let point = recognizer.locationInView(maskPanel)

        if !menuShow && self.catalogContainer.hidden {
            if inMenuRegion(point) {
                showMenu()
            } else if inNextRegion(point) {
                readerVC.snapToNextPage()
            } else if inPrevRegion(point) {
                readerVC.snapToPrevPage()
            }
        } else {
            if menuShow {
                hideMenu()
            } else {
                dismissCatalog()
            }
        }
    }

    private func inMenuRegion(p: CGPoint) -> Bool {
        return size.width / 3 < p.x && p.x < size.width * 2 / 3 && size.height / 3 < p.y && p.y < size.height * 2 / 3
    }

    private func inNextRegion(p: CGPoint) -> Bool {
        return (size.width * 2 / 3 <= p.x) || (size.width / 3 < p.x && size.height * 2 / 3 <= p.y)
    }

    private func inPrevRegion(p: CGPoint) -> Bool {
        return (p.x <= size.width / 3) || (p.x < size.width * 2 / 3 && p.y <= size.height / 3)
    }

    private func showMenu() {
        self.topBar.frame.origin.y    = -self.topBar.bounds.height
        self.bottomBar.frame.origin.y = self.size.height
        self.maskPanel.alpha          = 0.0
        self.topSubContainer.alpha    = 0.0

        self.menuShow                 = true
        self.topBar.hidden            = false
        self.bottomBar.hidden         = false
        self.maskPanel.hidden         = false
        
        UIView.animateWithDuration(R.Dimens.AnimInterval.Normal, delay: 0, options: .CurveEaseOut, animations: {
            UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .Slide)
            self.setNeedsStatusBarAppearanceUpdate()
            self.topBar.frame.origin.y    = 0
            self.maskPanel.alpha          = 0.1
            self.topSubContainer.alpha    = 1.0
            self.bottomBar.frame.origin.y = self.size.height - self.bottomBar.bounds.height
        }) { finish in }
    }

    private func hideMenu(animationCompeted:(()->Void)? = nil ) {
        self.menuShow = false
        self.btmSubContainer.userInteractionEnabled = false
        
        UIView.animateWithDuration(R.Dimens.AnimInterval.Normal, delay: 0, options: .CurveEaseOut, animations: {
            UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Slide)
            self.setNeedsStatusBarAppearanceUpdate()
            self.topBar.frame.origin.y          = -self.topBar.bounds.height
            self.bottomBar.frame.origin.y       = self.size.height
            self.btmSubContainer.frame.origin.y = self.size.height
            self.maskPanel.alpha                = 0
            self.topSubContainer.alpha          = 0
        }) { finish  in
            self.topBar.frame.origin.y             = -self.topBar.bounds.height
            self.bottomBar.frame.origin.y          = self.size.height
            self.stylePanelView.frame.origin.x     = 0
            self.styleFontsListView.frame.origin.x = self.size.width

            self.bottomBar.alpha       = 1
            self.maskPanel.alpha       = 0
            self.btmSubContainer.alpha = 0
            self.topSubContainer.alpha = 0

            self.topBar.hidden             = true
            self.bottomBar.hidden          = true
            self.maskPanel.hidden          = true
            self.stylePanelView.hidden     = true
            self.btmSubContainer.hidden    = true
            self.styleFontsListView.hidden = true
            
            if let end = animationCompeted { end() }
            
            if self.needReload {
                self.needReload = false
                self.reloadReader()
            }
        }
    }
    
    @IBAction func onStyleBtnClicked(sender: AnyObject) {
        stylePanelView.hidden                  = false
        btmSubContainer.hidden                 = false
        btmSubContainer.frame.origin.y         = self.size.height
        btmSubContainer.userInteractionEnabled = true
        
        self.stylePanelView.applyTheme()
        self.styleFontsListView.applyTheme()
        
        UIView.animateWithDuration(R.Dimens.AnimInterval.Normal, delay: 0, options: .CurveEaseOut, animations: {
            UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Fade)
            self.setNeedsStatusBarAppearanceUpdate()
            self.bottomBar.alpha                = 0
            self.btmSubContainer.alpha          = 1
            self.btmSubContainer.frame.origin.y = self.size.height - self.stylePanelHeight
        }) { finish in }
    }

    @IBAction func onCatalogBtnClicked(sender: AnyObject) {
        self.hideMenu { self.showCatalog() }
    }

    @IBAction func onJumpBtnClicked(sender: AnyObject) {
    }

    @IBAction func onSettingsBtnClicked(sender: AnyObject) {
    }

    private func showFontsList() {
        self.styleFontsListView.frame.origin.x = self.size.width
        self.styleFontsListView.hidden = false
        
        UIView.animateWithDuration(R.Dimens.AnimInterval.Normal, animations: {
            self.stylePanelView.frame.origin.x = -self.size.width
            self.styleFontsListView.frame.origin.x = 0
        }) { finish in }
    }

    private func showCatalog() {
        if catalogVC != nil {
            self.maskPanel.hidden = false
            self.catalogContainer.hidden = false
            self.catalogContainer.frame.origin.x = -self.catalogVC.view.frame.width
            UIView.animateWithDuration(R.Dimens.AnimInterval.Normal, animations: {
                self.maskPanel.alpha = 0.6
                self.catalogContainer.frame.origin.x = 0
            }) { finish in }
        }
    }

	private func dismissCatalog() {
		if catalogVC != nil {
			self.brightnessMask.userInteractionEnabled = true

			UIView.animateWithDuration(R.Dimens.AnimInterval.Normal, animations: {
				self.maskPanel.alpha = 0
				self.catalogContainer.frame.origin.x = -self.catalogVC.view.frame.width
			}) { finish in
				self.brightnessMask.userInteractionEnabled = false
				self.catalogContainer.hidden = true
				self.maskPanel.hidden = true
			}

			catalogVC.syncReaderStatus(readerMgr.book, currentChapter: readerMgr.currChapter)
		}
	}
}
