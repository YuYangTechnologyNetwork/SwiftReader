//
//  ReaderViewController.swift
//  NovelReader
//
//  Created by kang on 4/2/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit

class ReaderViewController: UIViewController, UIPageViewControllerDataSource,
UIPageViewControllerDelegate, UIScrollViewDelegate {

    @IBOutlet weak var overScrollView: UIView!

    private var currIndex: Int      = 0
    private var lastIndex: Int      = 0
    private var dataIsPrefect:Bool  = false
    private var completeCalled:Bool = false
    private var swipeCtrls: [PageViewController]!
    private var pageViewCtrl: UIPageViewController!

    private var head: Bool {
        return self.readerMgr.isHead || self.readerMgr.prevPaper == nil
    }

    private var tail: Bool {
        return self.readerMgr.isTail || self.readerMgr.nextPaper == nil
    }

    var readerMgr: ReaderManager! {
        didSet {
            readerMgr.addListener("Logging", forMonitor: ReaderManager.MonitorName.AsyncLoadFinish) { c in
                Utils.Log(self.readerMgr)
            }
        }
    }

    override func viewDidLoad() {
        pageViewCtrl = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
        pageViewCtrl.view.frame           = self.view.frame
        pageViewCtrl.delegate             = self
        pageViewCtrl.dataSource           = self
        pageViewCtrl.didMoveToParentViewController(self)
        
        addChildViewController(pageViewCtrl)
        view.addSubview(pageViewCtrl.view)

        for v in pageViewCtrl.view.subviews {
            if v.isKindOfClass(UIScrollView) {
                (v as! UIScrollView).delegate = self
            }
        }

        swipeCtrls = [
            PageViewController(nibName:"PageViewController", bundle: nil).index(0),
            PageViewController(nibName:"PageViewController", bundle: nil).index(1),
            PageViewController(nibName:"PageViewController", bundle: nil).index(2)
        ]
    }

	override func viewWillAppear(animated: Bool) {
		overScrollView.backgroundColor = Typesetter.Ins.theme.backgroundColor
        loadPapers()
	}

    func loadPapers() {
        swipeCtrls[currIndex].bindPaper(readerMgr.currPaper, doAnimation: true)

        if readerMgr.isHead {
            swipeCtrls[nextIndex(currIndex)].bindPaper(readerMgr.nextPaper)
        } else if readerMgr.isTail {
            swipeCtrls[prevIndex(currIndex)].bindPaper(readerMgr.prevPaper)
        } else {
            swipeCtrls[nextIndex(currIndex)].bindPaper(readerMgr.nextPaper)
            swipeCtrls[prevIndex(currIndex)].bindPaper(readerMgr.prevPaper)
        }

        pageViewCtrl.setViewControllers([swipeCtrls[currIndex]], direction: .Forward, animated: false) { e in }
    }

	func applyFormat() {
		if let curr = pageViewCtrl.viewControllers?[0] as? PageViewController {
			curr.applyFormat()
		}
	}
    
    func applyTheme() {
		swipeCtrls[currIndex].applyTheme()
		swipeCtrls[nextIndex(currIndex)].applyTheme(false)
        swipeCtrls[prevIndex(currIndex)].applyTheme(false)
        overScrollView.backgroundColor = Typesetter.Ins.theme.backgroundColor
	}

    func snapToPrevPage() {
        if !head {
            if let currVCtrl = pageViewCtrl.viewControllers?[0] as? PageViewController {
                readerMgr.swipToPrev()
                currVCtrl.bindPaper(readerMgr.currPaper, doAnimation: true)
                refreshPages()
            }
        }
    }

    func snapToNextPage() {
        if !tail {
            if let currVCtrl = pageViewCtrl.viewControllers?[0] as? PageViewController {
                readerMgr.swipToNext()
                currVCtrl.bindPaper(readerMgr.currPaper, doAnimation: true)
                refreshPages()
            }
        }
    }
    
    private func nextIndex(index: Int) -> Int {
        return index < 2 ? index + 1: 0
    }

    private func prevIndex(index: Int) -> Int {
        return index > 0 ? index - 1: 2
    }

    private func refreshPages() {
        if let pages = self.swipeCtrls {
            pages[nextIndex(currIndex)].bindPaper(readerMgr.nextPaper)
            pages[prevIndex(currIndex)].bindPaper(readerMgr.prevPaper)
            pageViewCtrl.setViewControllers([pages[self.currIndex]], direction: .Forward, animated: false) { e in }
        }
    }

    /**
     See UIPageViewControllerDelegate

     - parameter pageViewController: UIPageViewController
     - parameter v:                  Showing page controller

     - returns: Page controller of previous page
     */
    func pageViewController(pageViewController: UIPageViewController,
        viewControllerBeforeViewController v: UIViewController) -> UIViewController? {
            return head ? nil : swipeCtrls[prevIndex(currIndex)].bindPaper(readerMgr.prevPaper)
    }

    /**
     See UIPageViewControllerDelegate

     - parameter pageViewController: UIPageViewController
     - parameter v:                  Showing page controller

     - returns: Page controller of next page
     */
    func pageViewController(pageViewController: UIPageViewController,
        viewControllerAfterViewController v: UIViewController) -> UIViewController? {
            return tail ? nil : swipeCtrls[nextIndex(currIndex)].bindPaper(readerMgr.nextPaper)
    }

    /**
     See UIPageViewControllerDelegate

     - parameter pageViewController:     UIPageViewController
     - parameter pendingViewControllers: Will show page controller
     */
    func pageViewController(pageViewController: UIPageViewController,
                            willTransitionToViewControllers pendingViewControllers: [UIViewController]) {
        dataIsPrefect = true
        completeCalled = false
    }

    /**
     See UIPageViewControllerDelegate

     - parameter pageViewController:      UIPageViewController
     - parameter finished:                Animtion finished?
     - parameter previousViewControllers: Last showing controller
     - parameter completed:               Turn page completed?
     */
	func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
		previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
			if completed {
				if let currVCtrl = pageViewCtrl.viewControllers?[0] as? PageViewController {
					lastIndex = currIndex
					currIndex = currVCtrl.index

					if lastIndex == prevIndex(currIndex) {
						self.readerMgr.swipToNext()
					} else if lastIndex == nextIndex(currIndex) {
						self.readerMgr.swipToPrev()
					}
				}

                dataIsPrefect = false
                completeCalled = true
            }
	}

    /**
     See UIScrollViewDelegate
     
     - parameter scrollView: UIScrollView
     */
    func scrollViewDidScroll(scrollView: UIScrollView) {
		if Typesetter.Ins.theme == Theme.Parchment {
			let xOffset = scrollView.contentOffset.x - view.frame.width

            var justify = false
			if xOffset > 0 {
				overScrollView.frame.origin.x = view.frame.width - abs(xOffset)
                justify = readerMgr.nextPaper == nil
			} else if xOffset < 0 {
                overScrollView.frame.origin.x = abs(xOffset) - view.frame.width
                justify = readerMgr.prevPaper == nil
            }
            
            if xOffset % view.frame.width == 0 {
                overScrollView.hidden = !justify
                if !dataIsPrefect && !completeCalled {
                    completeCalled = true
                    refreshPages()
                }
			} else {
                let littleShow =  overScrollView.frame.origin.x < -view.frame.width / 3 ||
                    overScrollView.frame.origin.x > view.frame.width * 2 / 3 || justify
                overScrollView.hidden = dataIsPrefect ? true : !littleShow
			}
		}
    }
}
