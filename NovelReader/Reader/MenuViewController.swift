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

    private var readerManager: ReaderManager!
    private var stylePanelView: StylePanelView!
    private var readerController: ReaderViewController!
    private var catalogController: CatalogViewController!
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
				if let reader = self.readerController {
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
				self.readerManager = ReaderManager(b: b, size: self.view.frame.size)

				self.readerManager.addListener("MenuTitle", forMonitor: .ChapterChanged) { chapter in
					self.chapterTitle.text = chapter.title
				}

				self.readerManager.asyncLoading({ chapter in
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

    func reloadReader(withBlink: Bool = true) {
        if self.readerManager != nil {
            self.brightnessMask.userInteractionEnabled = true
            self.loadingIndicator.startAnimating()

            // Async reload
            self.readerManager.asyncLoading { _ in
                self.readerController.loadPapers(withBlink)
                self.loadingIndicator.stopAnimating()
                self.brightnessMask.userInteractionEnabled = false
            }
        }
    }
    
    func applyTheme() {
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

		if let rvc = self.readerController {
			rvc.applyTheme()
		}

        if catalogController != nil {
            catalogController.applyTheme()
        }
	}
    
	func attachReaderView(currChapter: Chapter) {
        self.chapterTitle.text           = currChapter.title
        self.readerController            = ReaderViewController(nibName: "ReaderViewController", bundle: nil)
        self.readerController.readerMgr  = self.readerManager
        self.readerController.view.frame = self.view.frame

        self.loadingIndicator.stopAnimating()
		self.addChildViewController(self.readerController)
		self.view.addSubview(self.readerController.view)
		self.view.sendSubviewToBack(self.readerController.view)
		self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.maskTaped(_:))))

        if !self.loadingBoardMask.hidden {
            UIView.animateWithDuration(0.3, animations: {
                self.loadingBoardMask.alpha  = 0
            }) { end in
                self.loadingBoardMask.hidden = true
                self.loadingBoardMask.alpha  = 1
            }
        }

        self.catalogController           = CatalogViewController(nibName: "CatalogViewController", bundle: nil)
        self.catalogController.book      = readerManager.book
        self.catalogController.view.frame = catalogContainer.frame
        self.catalogController.onDismiss { selected, bm in
            self.dismissCatalog()

            if selected {
                // Jump to selected chapter(bm)
            }
        }

        self.addChildViewController(catalogController)
        self.catalogContainer.addSubview(catalogController.view)

        self.catalogController.view.snp_makeConstraints { make in
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
                readerController.snapToNextPage()
            } else if inPrevRegion(point) {
                readerController.snapToPrevPage()
            }
        } else {
            if menuShow {
                hideMenu()
            } else {
                dismissCatalog()
            }
        }
    }

    func inMenuRegion(p: CGPoint) -> Bool {
        return size.width / 3 < p.x && p.x < size.width * 2 / 3 && size.height / 3 < p.y && p.y < size.height * 2 / 3
    }

    func inNextRegion(p: CGPoint) -> Bool {
        return (size.width * 2 / 3 <= p.x) || (size.width / 3 < p.x && size.height * 2 / 3 <= p.y)
    }

    func inPrevRegion(p: CGPoint) -> Bool {
        return (p.x <= size.width / 3) || (p.x < size.width * 2 / 3 && p.y <= size.height / 3)
    }

    func showMenu() {
        self.topBar.frame.origin.y    = -self.topBar.bounds.height
        self.bottomBar.frame.origin.y = self.size.height
        self.maskPanel.alpha          = 0.0
        self.topSubContainer.alpha    = 0.0

        self.menuShow                 = true
        self.topBar.hidden            = false
        self.bottomBar.hidden         = false
        self.maskPanel.hidden         = false
        
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseOut, animations: {
            UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .Slide)
            self.setNeedsStatusBarAppearanceUpdate()
            self.topBar.frame.origin.y    = 0
            self.maskPanel.alpha          = 1.0
            self.topSubContainer.alpha    = 1.0
            self.bottomBar.frame.origin.y = self.size.height - self.bottomBar.bounds.height
        }) { finish in }
    }

    func hideMenu(animationCompeted:(()->Void)? = nil ) {
        self.menuShow = false
        self.btmSubContainer.userInteractionEnabled = false
        
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseOut, animations: {
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
        
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseOut, animations: {
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

    func showFontsList() {
        self.styleFontsListView.frame.origin.x = self.size.width
        self.styleFontsListView.hidden = false
        
        UIView.animateWithDuration(0.3, animations: {
            self.stylePanelView.frame.origin.x = -self.size.width
            self.styleFontsListView.frame.origin.x = 0
        }) { finish in }
    }

    func showCatalog() {
        if catalogController != nil {
            self.maskPanel.hidden = false
            self.catalogContainer.hidden = false
            self.catalogContainer.frame.origin.x = -self.catalogController.view.frame.width
            UIView.animateWithDuration(0.3, animations: {
                self.maskPanel.alpha = 1
                self.catalogContainer.frame.origin.x = 0
            }) { finish in }
        }
    }

    func dismissCatalog() {
        if catalogController != nil {
            self.brightnessMask.userInteractionEnabled = true
            UIView.animateWithDuration(0.3, animations: {
                self.maskPanel.alpha = 0
                self.catalogContainer.frame.origin.x = -self.catalogController.view.frame.width
            }) { finish in
                self.brightnessMask.userInteractionEnabled = false
                self.catalogContainer.hidden = true
                self.maskPanel.hidden = true
            }
        }
    }
}
