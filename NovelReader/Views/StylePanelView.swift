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

    private var systemBirghtness:CGFloat = 0.5
    
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

	func applyTheme() {
        let tp                                      = Typesetter.Ins
        self.tintColor                              = tp.theme.foregroundColor
        self.backgroundColor                        = tp.theme.menuBackgroundColor

        self.vSplitLine.backgroundColor             = tp.theme.foregroundColor.newAlpha(0.05)
        self.hSplitLine.backgroundColor             = tp.theme.foregroundColor.newAlpha(0.05)
        self.themeSegment.selectedSegmentIndex      = tp.theme.rawValue

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
			Utils.color2Img(tp.theme.foregroundColor.newBrightness(trackBness), size: CGSizeMake(20, 20), circle: true),
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
}
