//
//  ReaderViewController.swift
//  NovelReader
//
//  Created by kang on 4/2/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit

class ReaderViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    private var currIndex: Int = 0
    private var lastIndex: Int = 0
    private var controllers: [PageViewController] = [PageViewController(), PageViewController(), PageViewController()]
    private var pageViewCtrler: UIPageViewController!
    
    private var theBackPageCtrler = PageViewController()
    
    @IBOutlet weak var prevBtn: UIButton!
    @IBOutlet weak var nextBtn: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        prevBtn.addTarget(self, action: #selector(ReaderViewController.snapToPrevPage), forControlEvents: .TouchUpInside)
        nextBtn.addTarget(self, action: #selector(ReaderViewController.snapToNextPage), forControlEvents: .TouchUpInside)
        
        pageViewCtrler = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
        pageViewCtrler.view.frame = self.view.frame
        pageViewCtrler.delegate = self
        pageViewCtrler.dataSource = self
        pageViewCtrler.doubleSided = true
        pageViewCtrler.didMoveToParentViewController(self)
        
        addChildViewController(pageViewCtrler)
        view.addSubview(pageViewCtrler.view)
        view.sendSubviewToBack(pageViewCtrler.view)
        
        let patch1 = UIImage(named: "reading_parchment1")
        let patch2 = UIImage(named: "reading_parchment2")
        let patch3 = UIImage(named: "reading_parchment3")
        
        let border = (patch1?.size.width)!
        let size = CGSizeMake(border * 2, 2 * border)
        
        UIGraphicsBeginImageContext(size);
        
        patch1?.drawInRect(CGRectMake(0, 0, border, border))
        patch3?.drawInRect(CGRectMake(0, border, border, border))
        patch2?.drawInRect(CGRectMake(border, 0, border, border))
        patch1?.drawInRect(CGRectMake(border, border, border, border))
        
        let resultingImage = UIGraphicsGetImageFromCurrentImageContext();
        
        view.backgroundColor = UIColor(patternImage: resultingImage)
        
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .None)
    }
    
    override func viewWillAppear(animated: Bool) {
        loadingIndicator.startAnimating()
        initliaze()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    private func initliaze() {
        Typesetter.Ins.font = FontManager.SupportFonts.SongTi
        Typesetter.Ins.fontSize = 19
        Typesetter.Ins.line_space = 10
        
        FontManager.asyncDownloadFont(Typesetter.Ins.font) { (_: Bool, _: String, _: String) in
            // Async load book content
            dispatch_async(dispatch_queue_create("ready_to_open_book", nil)) {
                let filePath = NSBundle.mainBundle().pathForResource("jy_gbk", ofType: "txt")
                let book = try! Book(fullFilePath: filePath!)
                ReaderManager.Ins.initalize(book, paperSize: self.view.frame.size)
                dispatch_async(dispatch_get_main_queue()) {
                    ReaderManager.Ins.asyncLoad() { (_: Bool) in
                        self.setPages()
                    }
                }
            }
        }
    }
    
    private func setPages() {
        controllers[currIndex].bindPaper(ReaderManager.Ins.currPaper())
        
        if ReaderManager.Ins.isHeader() {
            controllers[nextIndex(currIndex)].bindPaper(ReaderManager.Ins.nextPaper())
        } else if ReaderManager.Ins.isTail() {
            controllers[prevIndex(currIndex)].bindPaper(ReaderManager.Ins.prevPaper())
        } else {
            controllers[nextIndex(currIndex)].bindPaper(ReaderManager.Ins.nextPaper())
            controllers[prevIndex(currIndex)].bindPaper(ReaderManager.Ins.prevPaper())
        }
        
        pageViewCtrler.setViewControllers([controllers[currIndex]], direction: .Forward, animated: false, completion: nil)
        
        loadingIndicator.stopAnimating()
        loadingIndicator.hidden = true
    }
    
    func snapToPrevPage(view: UIView) {
        if !ReaderManager.Ins.isHeader() {
            currIndex = prevIndex(currIndex)
            ReaderManager.Ins.swipToPrev()
            pageViewCtrler.setViewControllers([controllers[currIndex]], direction: .Reverse, animated: true) {
                (_: Bool) in
                self.controllers[self.prevIndex(self.currIndex)].bindPaper(ReaderManager.Ins.prevPaper())
            }
        }
    }
    
    func snapToNextPage(view: UIView) {
        if !ReaderManager.Ins.isTail() {
            currIndex = nextIndex(currIndex)
            ReaderManager.Ins.swipToNext()
            pageViewCtrler.setViewControllers([controllers[currIndex]], direction: .Forward, animated: true) {
                (_: Bool) in
                self.controllers[self.nextIndex(self.currIndex)].bindPaper(ReaderManager.Ins.nextPaper())
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
            if ReaderManager.Ins.isHeader() {
                return nil
            }
            
            return controllers[prevIndex(currIndex)].bindPaper(ReaderManager.Ins.prevPaper())
    }
    
    /*UIPageViewControllerDataSource*/
    func pageViewController(pageViewController: UIPageViewController,
        viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
            if ReaderManager.Ins.isTail() {
                return nil
            }
            
            return controllers[nextIndex(currIndex)].bindPaper(ReaderManager.Ins.nextPaper())
    }
    
    /*UIPageViewControllerDelegate*/
    func pageViewController(pageViewController: UIPageViewController,
        willTransitionToViewControllers pendingViewControllers: [UIViewController]) { }
    
    /*UIPageViewControllerDelegate*/
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            if completed {
                lastIndex = currIndex
                currIndex = controllers.indexOf(pageViewController.viewControllers![0] as! PageViewController)!
                
                if lastIndex == prevIndex(currIndex) {
                    ReaderManager.Ins.swipToNext()
                } else if lastIndex == nextIndex(currIndex) {
                    ReaderManager.Ins.swipToPrev()
                }
                
                for v in pageViewController.view.subviews {
                    if v.isKindOfClass(UIScrollView) {
                        let scrollView = v as! UIScrollView
                        if scrollView.contentOffset.x % pageViewController.view.bounds.width == 0 {
                            // TODO: load buffer
                        }
                    }
                }
            }
    }
}