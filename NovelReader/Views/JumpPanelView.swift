//
//  JumpPanelView.swift
//  NovelReader
//
//  Created by kang on 27/11/2016.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit
import SnapKit

class JumpPanelView: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var btnPrevChapter: UIButton!
    @IBOutlet weak var btnNextChapter: UIButton!
    @IBOutlet weak var sliderNowProgress: UISlider!
    
    private var mJumpActionListener: ((ReaderManager.JumpType)->Void)?
    private var mSliderValueMonitor: ((CGFloat) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    private func commonInit() {
        NSBundle.mainBundle().loadNibNamed("JumpPanelView", owner: self, options: nil)
        
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(blankAction(_:))))
        self.addSubview(contentView)
        contentView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self)
            make.left.equalTo(self)
            make.right.equalTo(self)
            make.bottom.equalTo(self)
        }
    }
    
    func blankAction(_: UIView) { /*Just ignore */ }
    
    func applyTheme() {
        let tp                                       = Typesetter.Ins
        self.tintColor                               = tp.theme.foregroundColor
        self.backgroundColor                         = tp.theme.menuBackgroundColor
        
        self.btnPrevChapter.titleLabel?.textColor    = tp.theme.foregroundColor
        self.btnNextChapter.titleLabel?.textColor    = tp.theme.foregroundColor
        
        // self.sliderNowProgress.value                 = Float(tp.brightness)
        self.sliderNowProgress.maximumTrackTintColor = tp.theme.foregroundColor.newAlpha(0.5)
        self.sliderNowProgress.minimumTrackTintColor = tp.theme.foregroundColor
        
        let trackBness: CGFloat                      = tp.theme == Theme.Night ? 0.35 : 0.16
        self.sliderNowProgress.setThumbImage(
            Utils.color2Img(tp.theme.foregroundColor.newBrightness(trackBness), size: CGSizeMake(16, 16), circle: true),
            forState: .Normal
        )
    }
    
    func setJumpActionListener(closure: (ReaderManager.JumpType) -> Void) -> JumpPanelView {
        self.mJumpActionListener = closure
        return self
    }
    
    func setSliderValueMonitor(closure: (CGFloat) -> Void) -> JumpPanelView {
        self.mSliderValueMonitor = closure
        return self
    }
    
    func setNowProgress(precent: CGFloat) -> JumpPanelView {
        self.sliderNowProgress.setValue((Float)(precent), animated: false)
        return self
    }
    
    @IBAction func onPrevChapterBtnClicked(sender: AnyObject) {
        if let c = self.mJumpActionListener {
            c(.PrevChapter)
        }
    }
    
    @IBAction func onNextChapterBtnClicked(sender: AnyObject) {
        if let c = self.mJumpActionListener {
            c(.NextChapter)
        }
    }
    
    @IBAction func onProgressSliderValueChanged(sender: AnyObject) {
        if let c = self.mSliderValueMonitor {
            c(CGFloat(self.sliderNowProgress.value))
        }
    }
    
    @IBAction func onProgressSliderChanged(sender: AnyObject) {
        if let c = self.mJumpActionListener {
            c(.NewLocation(precent: CGFloat(self.sliderNowProgress.value)))
        }
    }
}
