//
//  LaunchViewController.swift
//  NovelReader
//
//  Created by kyongen on 5/24/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit

final class LaunchViewController: UIViewController {

    private var loaded: Bool = false
    private var splashvc: UIViewController?
    private var asyncTask: ((() -> Void) -> Void)? = nil
    private var readerMainCtrl: UIViewController!

    init(mainController: UIViewController, loading task: ((() -> Void) -> Void)? = nil) {
        super.init(nibName: nil, bundle: nil)
        readerMainCtrl = mainController
        self.asyncTask = task
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        showSplash()
    }

    override func prefersStatusBarHidden() -> Bool {
        return !self.loaded && readerMainCtrl.prefersStatusBarHidden()
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return readerMainCtrl.preferredStatusBarStyle()
    }

    private func showSplash() {
        if let task = asyncTask {
            if let splashStr = NSBundle.mainBundle().infoDictionary?["UILaunchStoryboardName"] as? String {
                Utils.Log(splashStr)
                let launchStoryboard = UIStoryboard(name: splashStr, bundle: nil)
                if let splashController = launchStoryboard.instantiateInitialViewController() {
                    splashvc = splashController
                    splashvc!.view.frame = self.view.frame
                    self.view.addSubview(splashvc!.view)
                    self.addChildViewController(splashvc!)

                    task {
                        self.displayMainController()
                    }
                }
            }
        }
    }

    func displayMainController() {
        readerMainCtrl.view.frame = self.view.frame
        self.addChildViewController(readerMainCtrl)
        self.view.addSubview(readerMainCtrl.view)
        self.view.sendSubviewToBack(readerMainCtrl.view)

        if let splash = splashvc {
            UIView.animateWithDuration(0.3, animations: {
                splash.view.alpha = 0
            }) { finish in
                splash.view.removeFromSuperview()
                splash.removeFromParentViewController()
            }
        }
    }
}
