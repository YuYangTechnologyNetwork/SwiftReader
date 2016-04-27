//
//  ReaderViewController.swift
//  NovelReader
//
//  Created by kangyonggen on 4/27/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit

class ReaderViewController: UIViewController {
    
@IBOutlet weak var topBar: UIView!
    @IBOutlet weak var bottomBar: UIView!
    @IBOutlet weak var stylePanel: UIView!
    @IBOutlet weak var maskPanel: UIView!
    
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
    var renderController: RenderViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .None)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return !menuShow
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
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.downZone = .None
        
        if !menuShow {
            let point = touches.first?.previousLocationInView(self.view)
            
            if let p = point {
                if inMenuRegion(p) {
                    Utils.Log("Down -> Menu")
                    downZone = .Menu
                } else if inPrevRegion(p) {
                    Utils.Log("Down -> Prev")
                    downZone = .Prev
                } else if inNextRegion(p) {
                    Utils.Log("Down -> Next")
                    downZone = .None
                }
            }
        }
        
        //super.touchesBegan(touches, withEvent: event)
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        if self.downZone != .None {
            self.downZone = .None
        }
        self.view.userInteractionEnabled = false
        //super.touchesCancelled(touches, withEvent: event)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if self.downZone != .None {
            self.downZone = .None
            Utils.Log("Move -> None")
        }
        
        //super.touchesBegan(touches, withEvent: event)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        switch downZone {
        case .Menu:
            Utils.Log("End -> Menu")
            showMenu()
        case .Next:
            Utils.Log("End -> Next")
        case .Prev:
            Utils.Log("End -> Prev")
        default:
            if menuShow {
                menuShow = false
                hideMenu()
            }
            
            //super.touchesBegan(touches, withEvent: event)
        }
    }
    
    func showMenu() {
        self.menuShow = true
        self.topBar.frame.origin.y = -self.topBar.bounds.height
        self.bottomBar.frame.origin.y = self.view.bounds.height
        self.maskPanel.alpha = 0.0
        self.topBar.hidden = false
        self.bottomBar.hidden = false
        self.maskPanel.hidden = false
        self.stylePanel.hidden = true
        
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Slide)
        
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseOut, animations: {
            self.topBar.frame.origin.y = 0
            self.bottomBar.frame.origin.y = self.view.bounds.height - self.bottomBar.bounds.height
            self.maskPanel.alpha = 1.0
            }, completion: nil)
    }
    
    func hideMenu() {
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Slide)
        
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseOut, animations: {
            self.topBar.frame.origin.y = -self.topBar.bounds.height
            self.bottomBar.frame.origin.y = self.view.bounds.height
            self.maskPanel.alpha = 0.0
        }) { (_: Bool) in
            self.topBar.hidden = true
            self.bottomBar.hidden = true
            self.maskPanel.hidden = true
            self.stylePanel.hidden = true
        }
    }
}
