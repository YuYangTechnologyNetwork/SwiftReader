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
    @IBOutlet weak var brightnessMinLabel: UILabel!
    @IBOutlet weak var brightnessMaxLabel: UILabel!

    private var showFontsList: (() -> Void)? = nil
    
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

		self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(blankAction(_:))))
		self.addSubview(contentView)

		contentView.snp_makeConstraints { (make) -> Void in
			make.top.equalTo(self)
			make.left.equalTo(self)
			make.right.equalTo(self)
			make.bottom.equalTo(self)
		}
	}

    func onShowFontsList(action: () -> Void) -> StylePanelView {
        self.showFontsList = action
        return self
    }

	func applyTheme() {
        let tp                                      = Typesetter.Ins
        self.tintColor                              = tp.theme.foregroundColor
        self.backgroundColor                        = tp.theme.menuBackgroundColor

        self.vSplitLine.backgroundColor             = tp.theme.foregroundColor.newAlpha(0.05)
        self.hSplitLine.backgroundColor             = tp.theme.foregroundColor.newAlpha(0.05)
        self.themeSegment.selectedSegmentIndex      = tp.theme.rawValue
        self.fontSetBtn.titleLabel?.font            = tp.font.forSize(15)

        self.marginLabel.textColor                  = tp.theme.foregroundColor.newAlpha(0.6)
        self.lineSpaceLabel.textColor               = tp.theme.foregroundColor.newAlpha(0.6)
        self.brightnessSlider.value                 = Float(tp.brightness)
        self.brightnessMinLabel.textColor           = tp.theme.foregroundColor
        self.brightnessMaxLabel.textColor           = tp.theme.foregroundColor
        self.brightnessSlider.maximumTrackTintColor = tp.theme.foregroundColor.newAlpha(0.1)
        self.brightnessSlider.minimumTrackTintColor = tp.theme.foregroundColor

        let trackBness: CGFloat                     = tp.theme == Theme.Night ? 0.35 : 0.16
        
		self.fontSetBtn.setTitle("\(tp.font.rawValue)         〉", forState: .Normal)
		self.brightnessSlider.setThumbImage(
			Utils.color2Img(tp.theme.foregroundColor.newBrightness(trackBness), size: CGSizeMake(16, 16), circle: true),
			forState: .Normal
		)
	}

	func blankAction(_: UIView) { /*Just ignore */ }

	@IBAction func onThemeChanged(sender: AnyObject) {
		Typesetter.Ins.theme = Theme(rawValue: themeSegment.selectedSegmentIndex)!
	}

    @IBAction func onBrightnessChanged(sender: AnyObject) {
        Typesetter.Ins.brightness = CGFloat(brightnessSlider.value / brightnessSlider.maximumValue)
    }
    
    @IBAction func onFontSizeChanged(sender: AnyObject) {
        let selected = fontSizeSegment.selectedSegmentIndex
        let fontSize = min(
            Typesetter.FontSize_Max,
            max(
                Typesetter.FontSize_Min,
                Typesetter.Ins.fontSize + 2 * (selected > 0 ? 1 : -1)
            )
        )
        
        if fontSize <= Typesetter.FontSize_Min {
            fontSizeSegment.setEnabled(false, forSegmentAtIndex: 0)
        } else if fontSize >= Typesetter.FontSize_Max {
            fontSizeSegment.setEnabled(false, forSegmentAtIndex: 1)
        } else {
            fontSizeSegment.setEnabled(true, forSegmentAtIndex: 0)
            fontSizeSegment.setEnabled(true, forSegmentAtIndex: 1)
        }
        
        Typesetter.Ins.fontSize = fontSize
    }
    
	@IBAction func decreaseLineSpace(sender: AnyObject) {
        Typesetter.Ins.line_space = max(Typesetter.LineSpace_Min, Typesetter.Ins.line_space - 1)
        lineSpaceDecBtn.enabled   = Typesetter.Ins.line_space > Typesetter.LineSpace_Min
        lineSpaceIncBtn.enabled   = true
	}

	@IBAction func increaseLineSpace(sender: AnyObject) {
        Typesetter.Ins.line_space = min(Typesetter.LineSpace_Max, Typesetter.Ins.line_space + 1)
        lineSpaceIncBtn.enabled   = Typesetter.Ins.line_space < Typesetter.LineSpace_Max
        lineSpaceDecBtn.enabled   = true
	}
    
	@IBAction func descreaseBoardMargin(sender: AnyObject) {
        var margin = Typesetter.Ins.margin
        margin.increase(-5, t: -5, r: -5, b: -5)
        margin.clamp(Typesetter.Margin_Min, up: Typesetter.Margin_Max)
        
        Typesetter.Ins.margin = margin
        marginDecBtn.enabled  = margin != Typesetter.Margin_Min
        marginIncBtn.enabled  = true
	}
    
    @IBAction func increaseBoardMargin(sender: AnyObject) {
        var margin = Typesetter.Ins.margin
        margin.increase(5, t: 5, r: 5, b: 5)
        margin.clamp(Typesetter.Margin_Min, up: Typesetter.Margin_Max)

        Typesetter.Ins.margin = margin
        marginIncBtn.enabled  = margin != Typesetter.Margin_Max
        marginDecBtn.enabled  = true
	}
    
	@IBAction func toSelectFontFamily(sender: AnyObject) {
        if let s = showFontsList {
            s()
        }
	}
}
