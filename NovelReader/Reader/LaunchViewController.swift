//
//  LaunchViewController.swift
//  NovelReader
//
//  Created by kyongen on 5/24/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit

final class LaunchViewController: UIViewController {
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var topContainerView: UIView!
    @IBOutlet weak var progressView: UIProgressView!

    private var loaded: Bool = false
    private var splashvc: UIViewController?
    private var asyncTask: ((LaunchViewController) -> Void)? = nil
    private var mainViewCtrler: UIViewController!

    init(mainController: UIViewController, loading task: ((LaunchViewController) -> Void)? = nil) {
        super.init(nibName: nil, bundle: nil)
        mainViewCtrler = mainController
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
        return !self.loaded || mainViewCtrler.prefersStatusBarHidden()
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return mainViewCtrler.preferredStatusBarStyle()
    }

    private func showSplash() {
        if let task = asyncTask {
            if let splashStr = NSBundle.mainBundle().infoDictionary?["UILaunchStoryboardName"] as? String {
                let launchStoryboard = UIStoryboard(name: splashStr, bundle: nil)
                if let splashController = launchStoryboard.instantiateInitialViewController() {
                    splashvc = splashController
                    splashvc!.view.frame = self.view.frame
                    self.view.addSubview(splashvc!.view)
                    self.addChildViewController(splashvc!)
                    self.view.bringSubviewToFront(self.topContainerView)
                    self.topContainerView.alpha = 0
                    
                    UIView.animateWithDuration(0.3) {
                        self.topContainerView.alpha = 1
                    }

                    task(self)
                }
            }
        }
    }
    
    func setProgressText(label: String?) {
        progressLabel.text = label
    }
    
    func setProgressValue(value:Float) {
        progressView.setProgress(value, animated: true)
    }

    func displayMainController() {
        mainViewCtrler.view.frame = self.view.frame
        self.addChildViewController(mainViewCtrler)
        self.view.addSubview(mainViewCtrler.view)
        self.view.sendSubviewToBack(mainViewCtrler.view)

        if let splash = splashvc {
            mainViewCtrler.view.alpha = 0
            UIView.animateWithDuration(0.3, animations: {
                self.topContainerView.alpha    = 0
                self.mainViewCtrler.view.alpha = 1
                splash.view.alpha              = 0
            }) { finish in
                self.topContainerView.removeFromSuperview()
                splash.view.removeFromSuperview()
                splash.removeFromParentViewController()
            }
        }
        
        self.loaded = true
    }
    
	func displayMainControllerDelay(delay: NSTimeInterval) {
		if delay > 0 {
			NSTimer.scheduledTimerWithTimeInterval(
				delay,
				target: self,
				selector: #selector(displayMainController),
				userInfo: nil,
				repeats: false
			)
		} else {
			displayMainController()
		}
	}
}
