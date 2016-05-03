//
//  StylePanelView.swift
//  NovelReader
//
//  Created by kang on 5/2/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit
import SnapKit

class StylePanelView: UIView {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var fontSetBtn: UIButton!
    @IBOutlet weak var vSplitLine: UIView!
    @IBOutlet weak var hSplitLine: UIView!
    @IBOutlet weak var lineSpaceDecBtn: UIButton!
    @IBOutlet weak var lineSpaceIncBtn: UIButton!
    @IBOutlet weak var lineSpaceLabel: UILabel!
    @IBOutlet weak var marginDecBtn: UIButton!
    @IBOutlet weak var marginIncBtn: UIButton!
    @IBOutlet weak var marginLabel: UILabel!
    @IBOutlet weak var themeSegment: UISegmentedControl!
    @IBOutlet weak var brightnessSlider: UISlider!
    @IBOutlet weak var fontSizeSegment: UISegmentedControl!
    
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
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(blankAction(_:))))
        self.addSubview(content)

        content.snp_makeConstraints{ (make) -> Void in
            make.top.equalTo(self)
            make.left.equalTo(self)
            make.right.equalTo(self)
            make.bottom.equalTo(self)
        }
    }

    func applyTheme() {
        self.tintColor = Typesetter.Ins.theme.foregroundColor
        self.backgroundColor = Typesetter.Ins.theme.menuBackgroundColor
        
        self.vSplitLine.backgroundColor = Typesetter.Ins.theme.foregroundColor.newAlpha(0.05)
        self.hSplitLine.backgroundColor = Typesetter.Ins.theme.foregroundColor.newAlpha(0.05)
        
        self.marginLabel.textColor = Typesetter.Ins.theme.foregroundColor.newAlpha(0.8)
        self.lineSpaceLabel.textColor = Typesetter.Ins.theme.foregroundColor.newAlpha(0.8)
        
        self.brightnessSlider.setThumbImage(Utils.color2Img(Typesetter.Ins.theme.foregroundColor, 
            size: CGSizeMake(20, 20), circle: true), forState: [.Normal])
        self.brightnessSlider.maximumTrackTintColor = Typesetter.Ins.theme.foregroundColor.newAlpha(0.1)
        self.brightnessSlider.minimumTrackTintColor = Typesetter.Ins.theme.foregroundColor.newBrightness(0.35)
    }

    func blankAction(_:UIView) {}

    override func updateConstraints() {
        super.updateConstraints()
        guard let content = contentView else { return }
        content.snp_remakeConstraints { (make) -> Void in
            make.top.equalTo(self)
            make.left.equalTo(self)
            make.right.equalTo(self)
            make.bottom.equalTo(self)
        }
    }
}
