//
//  PageViewController.swift
//  NovelReader
//
//  Created by kang on 4/2/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit

class PageViewController: UIViewController {
    @IBOutlet weak var containerView: YYLabel!
    @IBOutlet weak var boardMaskView: UIImageView!

    private var paper: Paper?
    private var needRefresh: Bool = true
    private var fadeIn: Bool = false

    override func viewDidLoad() {
        containerView.textVerticalAlignment = .Top
        containerView.displaysAsynchronously = true
        containerView.ignoreCommonProperties = true

        view.backgroundColor = Typesetter.Ins.theme.backgroundColor
        boardMaskView.hidden = !Typesetter.Ins.theme.boardMaskNeeded

        if let p = self.paper {
            p.attachToView(containerView)
        }
    }

    override func viewWillAppear(animated: Bool) {
        if self.needRefresh {
            needRefresh = false
            if let p = self.paper {
                p.attachToView(containerView)

                if fadeIn {
                    fadeIn = false
                    UIView.animateWithDuration(0.2) {
                        self.view.alpha = 0.0
                        self.view.alpha = 1.0
                    }
                }
            }
        }
    }

    func bindPaper(paper: Paper?, fadeIn: Bool = false) -> PageViewController {
        if let p = paper {
            self.needRefresh = self.paper == nil || self.paper?.text != p.text
            self.paper = p
            self.fadeIn = fadeIn
        }

        return self
    }
}