//
//  StyleFontsPickerView.swift
//  NovelReader
//
//  Created by kyongen on 6/2/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit
import YYText

class StyleFontsPickerView: UIView, UIPickerViewDataSource, UIPickerViewDelegate {
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var selectBtn: UIButton!
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var fontsPickerView: UIPickerView!

    private typealias `Self`       = StyleFontsPickerView
    private typealias Fonts        = FontManager.SupportFonts
    private static let LOOP_COUNT  = 65536
    private static let MiddleRange = NSMakeRange((LOOP_COUNT / 2 - 1) * Fonts.cases.count, Fonts.cases.count * 2)

    private var onFontChanged: ((Bool, Fonts) -> Void)?
    private var selectedFonts: Fonts = Typesetter.Ins.font

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    private func commonInit() {
        NSBundle.mainBundle().loadNibNamed("StyleFontsPickerView", owner: self, options: nil)
        self.addSubview(contentView)

        contentView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self)
            make.left.equalTo(self)
            make.right.equalTo(self)
            make.bottom.equalTo(self)
        }
    }

    func applyTheme() {
        let tp                          = Typesetter.Ins
        backgroundColor                 = tp.theme.menuBackgroundColor
        fontsPickerView.backgroundColor = UIColor.clearColor()
        cancelBtn.tintColor             = tp.theme.foregroundColor.newAlpha(0.8)
        selectBtn.tintColor             = tp.theme.foregroundColor.newAlpha(0.8)
        fontsPickerView.selectorColor   = tp.theme.foregroundColor.newAlpha(0.05)
        fontsPickerView.reloadComponent(0)
        fontsPickerView.selectRow(Fonts.cases.indexOf(tp.font)! + Self.MiddleRange.loc, inComponent: 0, animated: false)
    }

    func onFontsChanged(c: (chaged: Bool, selected: FontManager.SupportFonts) -> Void) -> StyleFontsPickerView {
        onFontChanged = c
        return self
    }

    @IBAction func onCancelBtnClicked(sender: AnyObject) {
        if let c = onFontChanged {
            c(false, selectedFonts)
        }
    }

    @IBAction func onSelectBtnClicked(sender: AnyObject) {
        if let c = onFontChanged {
            c(true, selectedFonts)
        }
    }

    // returns the number of 'columns' to display.
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }

    // returns the # of rows in each component..
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Fonts.cases.count * Self.LOOP_COUNT
    }

    func pickerView(pickerView: UIPickerView, viewForRow r: Int, forComponent: Int, reusingView v: UIView?) -> UIView {
        var label = v as? UILabel
        if label == nil {
            label = UILabel(frame: CGRectMake(0, 0, pickerView.frame.width, 32))
            label?.textColor = Typesetter.Ins.theme.foregroundColor
            label?.textAlignment = .Center
        }

        let font = Fonts.cases[r % Fonts.cases.count]
        label?.font = font.forSize(R.Dimension.FontSize.Com_Title)
        
        if font == Typesetter.Ins.font {
            label?.text = font.rawValue + "✓"
        } else {
            label?.text = font.rawValue
        }

        return label!
    }

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if !Self.MiddleRange.contain(row) {
            fontsPickerView.selectRow(row % Fonts.cases.count + Self.MiddleRange.loc, inComponent: 0, animated: false)
        }

        selectedFonts = Fonts.cases[row % Fonts.cases.count]
    }
}
