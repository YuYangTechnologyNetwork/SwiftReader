//
//  ReaderViewController.swift
//  NovelReader
//
//  Created by kang on 4/2/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit

class ReaderViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate {
    private var currIndex: Int = 0
    private var lastIndex: Int = 0
    private var readerMgr: ReaderManager!
    private var swipeCtrls: [PageViewController]!
    private var pageViewCtrl: UIPageViewController!
    
    @IBOutlet weak var prevBtn: UIButton!
    @IBOutlet weak var nextBtn: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var overScrollView: UIView!
    
    override func viewDidLoad() {
        prevBtn.addTarget(self, action: #selector(ReaderViewController.snapToPrevPage), forControlEvents: .TouchUpInside)
        nextBtn.addTarget(self, action: #selector(ReaderViewController.snapToNextPage), forControlEvents: .TouchUpInside)
        
        pageViewCtrl = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
        pageViewCtrl.view.frame  = self.view.frame
        pageViewCtrl.delegate    = self
        pageViewCtrl.dataSource  = self
        pageViewCtrl.didMoveToParentViewController(self)
        
        addChildViewController(pageViewCtrl)
        view.addSubview(pageViewCtrl.view)
        view.sendSubviewToBack(pageViewCtrl.view)
        view.backgroundColor = Typesetter.Ins.theme.backgroundColor
        
        for v in pageViewCtrl.view.subviews {
            if v.isKindOfClass(UIScrollView) {
                (v as! UIScrollView).delegate = self
            }
        }

        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .None)
    }
    
    override func viewWillAppear(animated: Bool) {
        loadingIndicator.color = Typesetter.Ins.theme.foregroundColor
        loadingIndicator.startAnimating()
        FontManager.asyncDownloadFont(Typesetter.Ins.font) {
            (success: Bool, fontName: String, msg: String) in
            if !success {
                Typesetter.Ins.font = FontManager.SupportFonts.System
            }
            
            self.initliaze()
        }
        
        overScrollView.backgroundColor = Typesetter.Ins.theme.backgroundColor
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    private func initliaze() {
        swipeCtrls = [PageViewController(), PageViewController(), PageViewController()]

        // Async load book content
        dispatch_async(dispatch_queue_create("ready_to_open_book", nil)) {
            let filePath = NSBundle.mainBundle().pathForResource("jy_gbk", ofType: "txt")
            let book = try! Book(fullFilePath: filePath!)
            dispatch_async(dispatch_get_main_queue()) {
                self.readerMgr = ReaderManager(b: book, size: self.view.frame.size)
                self.readerMgr.asyncPrepare({ (s: Chapter.Status) in
                    if s == Chapter.Status.Success {
                        self.setPages()
                    }
                })
            }
        }
    }
    
    private func setPages() {
        swipeCtrls[currIndex].bindPaper(readerMgr.currPaper)
        
        if readerMgr.isHead {
            swipeCtrls[nextIndex(currIndex)].bindPaper(readerMgr.nextPaper)
        } else if readerMgr.isTail {
            swipeCtrls[prevIndex(currIndex)].bindPaper(readerMgr.prevPaper)
        } else {
            swipeCtrls[nextIndex(currIndex)].bindPaper(readerMgr.nextPaper)
            swipeCtrls[prevIndex(currIndex)].bindPaper(readerMgr.prevPaper)
        }
        
        pageViewCtrl.setViewControllers([swipeCtrls[currIndex]], direction: .Forward, animated: false, completion: nil)
        loadingIndicator.stopAnimating()
        loadingIndicator.hidden = true
        
        UIView.animateWithDuration(0.3) {
            self.pageViewCtrl.view.alpha = 0.0
            self.pageViewCtrl.view.alpha = 1.0
        }
    }
    
    func snapToPrevPage(view: UIView) {
        if !readerMgr.isHead {
            currIndex = prevIndex(currIndex)
            readerMgr.swipToPrev()
            pageViewCtrl.setViewControllers([swipeCtrls[currIndex]], direction: .Reverse, animated: true) {
                (_: Bool) in
                self.swipeCtrls[self.prevIndex(self.currIndex)].bindPaper(self.readerMgr.prevPaper)
            }
        }
    }
    
    func snapToNextPage(view: UIView) {
        if !readerMgr.isTail {
            currIndex = nextIndex(currIndex)
            self.readerMgr.swipToNext()
            pageViewCtrl.setViewControllers([swipeCtrls[currIndex]], direction: .Forward, animated: true) {
                (_: Bool) in
                self.swipeCtrls[self.nextIndex(self.currIndex)].bindPaper(self.readerMgr.nextPaper)
            }
        }
    }
    
    private func nextIndex(index: Int) -> Int {
        return index < 2 ? index + 1: 0
    }
    
    private func prevIndex(index: Int) -> Int {
        return index > 0 ? index - 1: 2
    }
    
    /*UIPageViewControllerDataSource*/
    func pageViewController(pageViewController: UIPageViewController,
        viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
            if self.readerMgr.isHead || self.readerMgr.prevPaper == nil {
                return nil
            }
            
            return swipeCtrls[prevIndex(currIndex)].bindPaper(self.readerMgr.prevPaper)
    }
    
    /*UIPageViewControllerDataSource*/
    func pageViewController(pageViewController: UIPageViewController,
        viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if self.readerMgr.isTail || self.readerMgr.nextPaper == nil {
                return nil
            }
            
            return swipeCtrls[nextIndex(currIndex)].bindPaper(self.readerMgr.nextPaper)
    }
    
    /*UIPageViewControllerDelegate*/
    func pageViewController(pageViewController: UIPageViewController,
        willTransitionToViewControllers pendingViewControllers: [UIViewController]) { }
    
    /*UIPageViewControllerDelegate*/
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            if completed {
                lastIndex = currIndex
                currIndex = swipeCtrls.indexOf(pageViewController.viewControllers![0] as! PageViewController)!
                
                if lastIndex == prevIndex(currIndex) {
                    self.readerMgr.swipToNext()
                } else if lastIndex == nextIndex(currIndex) {
                    self.readerMgr.swipToPrev()
                }
                
                overScrollView.hidden = true
            }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if Typesetter.Ins.theme.name == Theme.PARCHMENT {
            if (readerMgr.isTail || readerMgr.isHead) {
                let xOffset = scrollView.contentOffset.x - view.frame.width
                
                if readerMgr.isTail && xOffset > 0 {
                    overScrollView.frame.origin.x = view.frame.width - abs(xOffset)
                } else if readerMgr.isHead && xOffset < 0 {
                    overScrollView.frame.origin.x = abs(xOffset) - view.frame.width
                }
                
                let osvX = overScrollView.frame.origin.x
                if osvX < -view.frame.width / 2 || osvX > view.frame.width / 2 {
                    overScrollView.hidden = false
                    overScrollView.setNeedsDisplay()
                }
                
                Utils.Log(xOffset)
            }
        }
    }
}