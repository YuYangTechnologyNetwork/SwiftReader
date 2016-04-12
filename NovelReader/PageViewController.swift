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
    
    private var paper: Paper?
    private var needRefresh: Bool = true
    
    override func viewDidLoad() {
        containerView.textVerticalAlignment = .Top
        containerView.displaysAsynchronously = true
        containerView.ignoreCommonProperties = true

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
        view.addSubview(containerView)
        
        if self.paper != nil {
            self.paper?.attachToView(containerView)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        if self.needRefresh {
            paper?.attachToView(containerView)
            needRefresh = false
        }
    }

    func bindPaper(paper: Paper?) -> PageViewController {
        if paper != nil {
            self.needRefresh = self.paper?.text != paper?.text
            self.paper = paper
            
            if containerView != nil {
                self.paper?.attachToView(containerView)
            }
        }
        
        return self
    }
    
    override var description: String {
        return paper != nil ? (paper?.text.substringToIndex((paper?.text.startIndex.advancedBy(4))!))! : super.description
    }
}