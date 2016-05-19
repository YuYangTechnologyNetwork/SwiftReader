//
//  PageViewController.swift
//  NovelReader
//
//  Created by kang on 4/2/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit
import YYText

class PageViewController: UIViewController {
    @IBOutlet weak var containerView: YYLabel!
    @IBOutlet weak var boardMaskView: UIImageView!

    private var paper: Paper?
    private var needRefresh: Bool = true
    private var _index:Int = 0

    var index:Int {
        return _index
    }

    override func viewDidLoad() {
        containerView.textVerticalAlignment = .Top
        applyTheme()
    }

    override func viewWillAppear(animated: Bool) {
        boardMaskView.hidden = Typesetter.Ins.theme.name != Theme.PARCHMENT
        
        if self.needRefresh {
            needRefresh = false
            if let p = self.paper {
                p.attachToView(containerView)
            }
        }
    }

    func index(index: Int) -> PageViewController {
        _index = index
        return self
    }
    
	func applyTheme() {
		if nil != paper && containerView != nil {
            containerView.backgroundColor = UIColor.clearColor()
			paper!.attachToView(self.containerView, applyTheme: true)
		}

		if boardMaskView != nil {
			boardMaskView.hidden = Typesetter.Ins.theme.name != Theme.PARCHMENT
		}

		if let old = Typesetter.Ins.oldTheme {
            if old.name == Theme.Info.Parchment.name {
                self.view.backgroundColor = old.menuBackgroundColor
            }
		}

		UIView.animateWithDuration(0.3) {
			self.view.backgroundColor = Typesetter.Ins.theme.backgroundColor
		}
	}

    func bindPaper(paper: Paper?) -> PageViewController? {
        if let p = paper {
            if let yylabel = self.containerView {
                p.attachToView(yylabel)
            } else {
                self.needRefresh = self.paper == nil || self.paper?.text != p.text
                self.paper = p
            }
            return self
        } else {
            return nil
        }
    }
}