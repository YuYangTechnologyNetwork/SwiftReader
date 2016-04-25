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
            if let p = self.paper {
                p.attachToView(containerView)
                needRefresh = false
            }

        }
    }

    func bindPaper(paper: Paper?) -> PageViewController {
        if let p = paper {
            self.needRefresh = self.paper == nil || self.paper?.text != p.text
            self.paper = p
        }

        return self
    }
    
    override var description: String {
        return paper != nil ? (paper?.text.substringToIndex((paper?.text.startIndex.advancedBy(4))!))! : super.description
    }
}