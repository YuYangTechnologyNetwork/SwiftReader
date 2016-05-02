//
//  StylePanelView.swift
//  NovelReader
//
//  Created by kang on 5/2/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit

class StylePanelView: UIView {

    @IBOutlet var contentView: UIView!
    
    override init(frame: CGRect) {	
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    private func commonInit() {
        NSBundle.mainBundle().loadNibNamed("StylePanelView", owner: self, options: nil)
        guard let content = contentView else { return }
        content.frame = self.bounds
        //content.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        self.addSubview(content)
    }
}
