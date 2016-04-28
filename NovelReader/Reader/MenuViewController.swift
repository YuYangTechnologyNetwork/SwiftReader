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
    @IBOutlet weak var stylePanel: UIView!
    @IBOutlet weak var chapterTitle: UILabel!

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
    var renderController: ReaderViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Typesetter.Ins.theme = Theme.Night()

        renderController = ReaderViewController()
        addChildViewController(renderController)

        view.addSubview(renderController.view)
        view.sendSubviewToBack(renderController.view)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(maskPanelTaped(_:))))
    }

    override func viewWillAppear(animated: Bool) {
        self.topBar.tintColor = Typesetter.Ins.theme.foregroundColor
        self.bottomBar.tintColor = Typesetter.Ins.theme.foregroundColor
        self.chapterTitle.textColor = Typesetter.Ins.theme.foregroundColor
        
        self.topBar.backgroundColor = Typesetter.Ins.theme.menuBackgroundColor
        self.bottomBar.backgroundColor = Typesetter.Ins.theme.menuBackgroundColor
    }

    override func prefersStatusBarHidden() -> Bool {
        return !menuShow
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return Typesetter.Ins.theme.statusBarStyle
    }

    func maskPanelTaped(recognizer: UITapGestureRecognizer) {
        let point = recognizer.locationInView(maskPanel)

        if !menuShow {
            if inMenuRegion(point) {
                showMenu()
            } else if inNextRegion(point) {
                renderController.snapToNextPage()
            } else if inPrevRegion(point) {
                renderController.snapToPrevPage()
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
        self.stylePanel.hidden = true

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
            self.bottomBar.frame.origin.y = self.view.bounds.height
            self.maskPanel.alpha = 0.0
            self.topSubContainer.alpha = 0.0
        }) { (finish: Bool) in
            self.topBar.hidden = true
            self.bottomBar.hidden = true
            self.maskPanel.hidden = true
            self.stylePanel.hidden = true

            if !finish {
                self.topBar.frame.origin.y = -self.topBar.bounds.height
                self.bottomBar.frame.origin.y = self.view.bounds.height
                self.maskPanel.alpha = 0.0
                self.topSubContainer.alpha = 0.0
            }
        }
    }
}
