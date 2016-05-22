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
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    @IBOutlet weak var topSubContainer: UIView!
    @IBOutlet weak var btmSubContainer: UIView!

    var size: CGSize {
        return self.view.bounds.size
    }

    enum DownZone {
        case None
        case Menu
        case Next
        case Prev
    }

    var menuShow: Bool = false
    var downZone: DownZone = .None
    var readerManager: ReaderManager!
    var stylePanelView: StylePanelView!
    var readerController: ReaderViewController!

    let stylePanelHeight:CGFloat = 190

	override func viewDidLoad() {
		super.viewDidLoad()

		loadingIndicator.color = Typesetter.Ins.theme.foregroundColor
		stylePanelView = StylePanelView(frame: CGRectMake(0, 0, self.view.bounds.width, stylePanelHeight))

        btmSubContainer.addSubview(stylePanelView)

		Typesetter.Ins.addListener("MenuListener") { field, oldValue in
			if "Theme" == field {
				self.hideMenu { self.applyTheme() }
				Utils.Log(Typesetter.Ins.theme.name)
			}
		}
	}

    override func viewWillAppear(animated: Bool) {
        self.applyTheme()
        
        // Start loading
        self.loadingIndicator.startAnimating()

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let filePath = NSBundle.mainBundle().pathForResource(BUILD_BOOK, ofType: "txt")
            let book = Book(fullFilePath: filePath!)
            dispatch_async(dispatch_get_main_queue()) {
				if let b = book {
					self.readerManager = ReaderManager(b: b, size: self.view.frame.size)

					self.readerManager.addListener("MenuTitle", forMonitor: ReaderManager.MonitorName.ChapterChanged) {
						chapter in
						self.chapterTitle.text = chapter.title
					}

					self.readerManager.asyncPrepare({ (chapter: Chapter) in
						self.attachReaderView(chapter)
					})
				}
            }
        }

        stylePanelView.snp_makeConstraints { (make) -> Void in
            make.width.equalTo(self.btmSubContainer.snp_width)
            make.height.equalTo(stylePanelHeight)
            make.top.equalTo(self.btmSubContainer.snp_top)
            make.left.equalTo(self.btmSubContainer.snp_left)
        }
    }

    override func prefersStatusBarHidden() -> Bool {
        return !menuShow
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return Typesetter.Ins.theme.statusBarStyle
    }
    
    func applyTheme() {
        self.topBar.tintColor          = Typesetter.Ins.theme.foregroundColor
        self.bottomBar.tintColor       = Typesetter.Ins.theme.foregroundColor
        self.view.backgroundColor      = Typesetter.Ins.theme.backgroundColor
        self.chapterTitle.textColor    = Typesetter.Ins.theme.foregroundColor
        self.topBar.backgroundColor    = Typesetter.Ins.theme.menuBackgroundColor
        self.bottomBar.backgroundColor = Typesetter.Ins.theme.menuBackgroundColor

		if let rvc = self.readerController {
			rvc.applyTheme()
		}

        self.stylePanelView.applyTheme()
	}
    
    func attachReaderView(currChapter: Chapter) {
        FontManager.asyncDownloadFont(Typesetter.Ins.font) { (success: Bool, fontName: String, msg: String) in
            self.loadingIndicator.stopAnimating()
            self.loadingIndicator.hidden = true
            self.chapterTitle.text       = currChapter.title
            
            if !success {
                Typesetter.Ins.font = FontManager.SupportFonts.System
            }

            self.readerController            = ReaderViewController()
            self.readerController.readerMgr  = self.readerManager
            self.readerController.view.frame = self.view.frame
            
            self.addChildViewController(self.readerController)
            self.view.addSubview(self.readerController.view)
            self.view.sendSubviewToBack(self.readerController.view)
            self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.maskTaped(_:))))
        }
    }

    func maskTaped(recognizer: UITapGestureRecognizer) {
        let point = recognizer.locationInView(maskPanel)

        if !menuShow {
            if inMenuRegion(point) {
                showMenu()
            } else if inNextRegion(point) {
                readerController.snapToNextPage()
            } else if inPrevRegion(point) {
                readerController.snapToPrevPage()
            }
        } else {
            hideMenu()
        }
    }

    func inMenuRegion(p: CGPoint) -> Bool {
        return size.width / 3 < p.x && p.x < size.width * 2 / 3 && size.height / 3 < p.y && p.y < size.height * 3 / 3
    }

    func inNextRegion(p: CGPoint) -> Bool {
        return (size.width * 3 / 3 <= p.x) || (size.width / 3 < p.x && size.height * 2 / 3 <= p.y)
    }

    func inPrevRegion(p: CGPoint) -> Bool {
        return (p.x <= size.width / 3) || (p.x < size.width * 2 / 3 && p.y <= size.height / 3)
    }

    func showMenu() {
        self.topBar.frame.origin.y    = -self.topBar.bounds.height
        self.bottomBar.frame.origin.y = self.view.bounds.height
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
            self.bottomBar.frame.origin.y = self.view.bounds.height - self.bottomBar.bounds.height
        }) { finish in
            self.topBar.frame.origin.y    = 0
            self.maskPanel.alpha          = 1.0
            self.topSubContainer.alpha    = 1.0
            self.bottomBar.frame.origin.y = self.view.bounds.height - self.bottomBar.bounds.height
        }
    }

    func hideMenu(animationCompeted:(()->Void)? = nil ) {
        self.menuShow = false
        self.btmSubContainer.userInteractionEnabled = false

        UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseOut, animations: {
            UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Slide)
            self.setNeedsStatusBarAppearanceUpdate()
            self.topBar.frame.origin.y          = -self.topBar.bounds.height
            self.bottomBar.frame.origin.y       = self.view.bounds.height
            self.btmSubContainer.frame.origin.y = self.view.bounds.height
            self.maskPanel.alpha                = 0
            self.topSubContainer.alpha          = 0
        }) { finish  in
            self.topBar.frame.origin.y    = -self.topBar.bounds.height
            self.bottomBar.frame.origin.y = self.view.bounds.height

            self.bottomBar.alpha          = 1
            self.maskPanel.alpha          = 0.0
            self.btmSubContainer.alpha    = 0
            self.topSubContainer.alpha    = 0.0

            self.topBar.hidden            = true
            self.bottomBar.hidden         = true
            self.maskPanel.hidden         = true
            self.stylePanelView.hidden    = true
            self.btmSubContainer.hidden   = true
            
            if let end = animationCompeted {
                end()
            }
        }
    }
    
    @IBAction func onStyleBtnClicked(sender: AnyObject) {
        stylePanelView.hidden                  = false
        btmSubContainer.hidden                 = false
        btmSubContainer.frame.origin.y         = self.view.bounds.height
        btmSubContainer.userInteractionEnabled = true
        showStylePanel()
    }
    
    func showStylePanel() {
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseOut, animations: {
            UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Fade)
            self.setNeedsStatusBarAppearanceUpdate()
            self.bottomBar.alpha                = 0
            self.btmSubContainer.alpha          = 1
            self.btmSubContainer.frame.origin.y = self.view.bounds.height - self.stylePanelHeight
        }) { finish in }
    }
}
