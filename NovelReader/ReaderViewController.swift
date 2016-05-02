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
    private var swipeCtrls: [PageViewController]!
    private var pageViewCtrl: UIPageViewController!

    private var head: Bool {
        return self.readerMgr.isHead || self.readerMgr.prevPaper == nil
    }

    private var tail: Bool {
        return self.readerMgr.isTail || self.readerMgr.nextPaper == nil
    }
    
    var readerMgr: ReaderManager!
    
    @IBOutlet weak var overScrollView: UIView!

    override func viewDidLoad() {
        pageViewCtrl = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
        pageViewCtrl.view.frame = self.view.frame
        pageViewCtrl.delegate = self
        pageViewCtrl.dataSource = self
        pageViewCtrl.didMoveToParentViewController(self)

        addChildViewController(pageViewCtrl)
        view.addSubview(pageViewCtrl.view)
        view.sendSubviewToBack(pageViewCtrl.view)

        view.backgroundColor = Typesetter.Ins.theme.backgroundColor
        overScrollView.backgroundColor = Typesetter.Ins.theme.backgroundColor

        for v in pageViewCtrl.view.subviews {
            if v.isKindOfClass(UIScrollView) {
                (v as! UIScrollView).delegate = self
            }
        }
    }

    override func viewWillAppear(animated: Bool) {
        bindPages()
    }

    func bindPages(animation: Bool = true) {
        swipeCtrls = [PageViewController(), PageViewController(), PageViewController()]
        swipeCtrls[currIndex].bindPaper(readerMgr.currPaper, fadeIn: true)

        if readerMgr.isHead {
            swipeCtrls[nextIndex(currIndex)].bindPaper(readerMgr.nextPaper)
        } else if readerMgr.isTail {
            swipeCtrls[prevIndex(currIndex)].bindPaper(readerMgr.prevPaper)
        } else {
            swipeCtrls[nextIndex(currIndex)].bindPaper(readerMgr.nextPaper)
            swipeCtrls[prevIndex(currIndex)].bindPaper(readerMgr.prevPaper)
        }

        pageViewCtrl.setViewControllers([swipeCtrls[currIndex]], direction: .Forward, animated: false, completion: nil)
    }

    func snapToPrevPage() {
        if !head {
            pageViewCtrl.setViewControllers([swipeCtrls[prevIndex(currIndex)]], direction: .Reverse, animated: true) {
                (_: Bool) in
                self.currIndex = self.prevIndex(self.currIndex)
                self.readerMgr.swipToPrev()
                self.swipeCtrls[self.prevIndex(self.currIndex)].bindPaper(self.readerMgr.prevPaper)
            }
        }
    }

    func snapToNextPage() {
        if !tail {
            pageViewCtrl.setViewControllers([swipeCtrls[nextIndex(currIndex)]], direction: .Forward, animated: true) {
                (_: Bool) in
                self.currIndex = self.nextIndex(self.currIndex)
                self.readerMgr.swipToNext()
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
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        return head ? nil : swipeCtrls[prevIndex(currIndex)].bindPaper(self.readerMgr.prevPaper)
    }

    /*UIPageViewControllerDataSource*/
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        return tail ? nil : swipeCtrls[nextIndex(currIndex)].bindPaper(self.readerMgr.nextPaper)
    }

    /*UIPageViewControllerDelegate*/
    func pageViewController(pageViewController: UIPageViewController,
        willTransitionToViewControllers pendingViewControllers: [UIViewController]) {
    }

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
            if (readerMgr.prevPaper == nil || readerMgr.nextPaper == nil) {
                let xOffset = scrollView.contentOffset.x - view.frame.width

                if readerMgr.nextPaper == nil && xOffset > 0 {
                    overScrollView.frame.origin.x = view.frame.width - abs(xOffset)
                } else if readerMgr.prevPaper == nil && xOffset < 0 {
                    overScrollView.frame.origin.x = abs(xOffset) - view.frame.width
                }

                let osvX = overScrollView.frame.origin.x
                if osvX < -view.frame.width / 2 || osvX > view.frame.width / 2 {
                    overScrollView.hidden = false
                    overScrollView.setNeedsDisplay()
                }
            }
        }
    }
}