//
//  ReaderViewController.swift
//  NovelReader
//
//  Created by kangyonggen on 4/27/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var topBar: UIView!
    @IBOutlet weak var bottomBar: UIView!
    @IBOutlet weak var maskPanel: UIView!
    @IBOutlet weak var chapterTitle: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    @IBOutlet weak var topSubContainer: UIView!
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*Typesetter.Ins.theme = Theme.Night()*/
        loadingIndicator.color = Typesetter.Ins.theme.foregroundColor
        
        stylePanelView = StylePanelView(frame: CGRectMake(0, 0, self.view.bounds.width, 158))
        stylePanelView.hidden = true
        self.bottomBar.addSubview(stylePanelView)
    }

    override func viewWillAppear(animated: Bool) {
        self.topBar.tintColor = Typesetter.Ins.theme.foregroundColor
        self.bottomBar.tintColor = Typesetter.Ins.theme.foregroundColor
        self.chapterTitle.textColor = Typesetter.Ins.theme.foregroundColor
        
        self.topBar.backgroundColor = Typesetter.Ins.theme.menuBackgroundColor
        self.bottomBar.backgroundColor = Typesetter.Ins.theme.menuBackgroundColor
        
        // Start loading
        self.loadingIndicator.startAnimating()

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            let filePath = NSBundle.mainBundle().pathForResource("zx_utf8", ofType: "txt")
            let book = try! Book(fullFilePath: filePath!)
            
            dispatch_async(dispatch_get_main_queue()) {
                self.readerManager = ReaderManager(b: book, size: self.view.frame.size)
                
                self.readerManager.addListener("menu-title") { (chapter: Chapter) in
                    self.chapterTitle.text = chapter.title
                }
                
                self.readerManager.asyncPrepare({ (chapter: Chapter) in
                    self.attachReaderView(chapter)
                })
            }
        }
    }

    override func prefersStatusBarHidden() -> Bool {
        return !menuShow
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return Typesetter.Ins.theme.statusBarStyle
    }
    
    func attachReaderView(currChapter: Chapter) {
        FontManager.asyncDownloadFont(Typesetter.Ins.font) { (success: Bool, fontName: String, msg: String) in
            
            self.loadingIndicator.stopAnimating()
            self.loadingIndicator.hidden = true
            self.chapterTitle.text = currChapter.title
            
            if !success {
                Typesetter.Ins.font = FontManager.SupportFonts.System
            }

            self.readerController = ReaderViewController()
            self.readerController.readerMgr = self.readerManager
            self.readerController.view.frame = self.view.frame
            
            self.addChildViewController(self.readerController)
            self.view.addSubview(self.readerController.view)
            self.view.sendSubviewToBack(self.readerController.view)
            self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.maskPanelTaped(_:))))
        }
    }

    func maskPanelTaped(recognizer: UITapGestureRecognizer) {
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
        return size.width / 4 < p.x && p.x < size.width * 3 / 4 && size.height / 4 < p.y && p.y < size.height * 3 / 4
    }

    func inNextRegion(p: CGPoint) -> Bool {
        return (size.width * 3 / 4 <= p.x) || (size.width / 4 < p.x && size.height * 3 / 4 <= p.y)
    }

    func inPrevRegion(p: CGPoint) -> Bool {
        return (p.x <= size.width / 4) || (p.x < size.width * 3 / 4 && p.y <= size.height / 4)
    }

    func showMenu() {
        self.topBar.frame.origin.y = -self.topBar.bounds.height
        self.bottomBar.frame.origin.y = self.view.bounds.height
        self.maskPanel.alpha = 0.0
        self.topSubContainer.alpha = 0.0

        self.menuShow = true
        self.topBar.hidden = false
        self.bottomBar.hidden = false
        self.maskPanel.hidden = false

        UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseOut, animations: {
            UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: .Slide)
            self.setNeedsStatusBarAppearanceUpdate()
            self.topBar.frame.origin.y = 0
            self.bottomBar.frame.origin.y = self.view.bounds.height - self.bottomBar.bounds.height
            self.maskPanel.alpha = 1.0
            self.topSubContainer.alpha = 1.0
        }) { (finish: Bool) in
            if !finish {
                self.topBar.frame.origin.y = 0
                self.bottomBar.frame.origin.y = self.view.bounds.height - self.bottomBar.bounds.height
                self.maskPanel.alpha = 1.0
                self.topSubContainer.alpha = 1.0
            }
        }
    }

    func hideMenu() {
        self.menuShow = false
        
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseOut, animations: {
            UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Fade)
            self.setNeedsStatusBarAppearanceUpdate()
            self.topBar.frame.origin.y = -self.topBar.bounds.height
            self.bottomBar.frame = CGRectMake(0, self.view.bounds.height, self.view.bounds.width, 48)
            self.maskPanel.alpha = 0.0
            self.topSubContainer.alpha = 0.0
        }) { (finish: Bool) in
            self.topBar.hidden = true
            self.bottomBar.hidden = true
            self.maskPanel.hidden = true
            self.topBar.frame.origin.y = -self.topBar.bounds.height
            self.bottomBar.frame = CGRectMake(0, self.view.bounds.height, self.view.bounds.width, 48)
            self.maskPanel.alpha = 0.0
            self.topSubContainer.alpha = 0.0
            
            self.stylePanelView.hidden = true
            self.stylePanelView.alpha = 0
        }
    }
    
    @IBAction func onStyleBtnClicked(sender: AnyObject) {
        showStylePanel()
    }
    
    func showStylePanel() {
        self.stylePanelView.hidden = false
        self.stylePanelView.alpha = 0
        
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseOut, animations: {
            UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Fade)
            self.setNeedsStatusBarAppearanceUpdate()
            self.bottomBar.frame = CGRectMake(0, self.view.bounds.height - 158, self.view.bounds.width, 158)
            self.stylePanelView.frame = CGRectMake(0, self.view.bounds.height - 158, self.view.bounds.width, 158)
            self.stylePanelView.alpha = 1.0
        }) { (finish: Bool) in
            self.bottomBar.frame = CGRectMake(0, self.view.bounds.height - 158, self.view.bounds.width, 158)
            //self.stylePanelView.frame = self.bottomBar.frame
        }
    }
}
