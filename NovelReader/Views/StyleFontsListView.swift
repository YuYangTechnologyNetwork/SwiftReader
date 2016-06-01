//
//  StyleFontsListView.swift
//  NovelReader
//
//  Created by kyongen on 6/1/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit
import SnapKit

class StyleFontsListView: UIView, UITableViewDataSource, UITableViewDelegate {
    private typealias Fonts = FontManager.SupportFonts

    @IBOutlet weak var fontsListView: UITableView!
    @IBOutlet var contentView: StyleFontsListView!

    private var cellSelectBg:UIView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    private func commonInit() {
        NSBundle.mainBundle().loadNibNamed("StyleFontsListView", owner: self, options: nil)

        self.addSubview(contentView)
        self.fontsListView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.fontsListView.dataSource = self
        self.fontsListView.delegate = self

        fontsListView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self)
            make.left.equalTo(self)
            make.right.equalTo(self)
            make.bottom.equalTo(self)
        }

        cellSelectBg = UIView()
    }

    func applyTheme() {
        let tp                                      = Typesetter.Ins
        self.backgroundColor                        = tp.theme.menuBackgroundColor
        self.fontsListView.backgroundColor          = UIColor.clearColor()
        self.fontsListView.separatorColor           = tp.theme.foregroundColor.newAlpha(0.05)
        self.cellSelectBg.backgroundColor           = tp.menuBackgroundColor.newBrightness(0.7).newß tp.theme == Theme.Night ? 0.35 : 0.16
        self.fontsListView.reloadData()
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Fonts.cases.count
    }

    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and 
    // querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and 
    // data source (accessory views, editing controls)
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")
        cell?.textLabel?.text = Fonts.cases[indexPath.row].rawValue
        cell?.textLabel?.textColor = Typesetter.Ins.theme.foregroundColor
        cell?.backgroundColor = Typesetter.Ins.theme.menuBackgroundColor

        let bgView = UIView()
        bgView.backgroundColor = Typesetter.Ins.theme.menuBackgroundColor.newBrightness(0.7).newAlpha(0.4)
        cell?.selectedBackgroundView = bgView

        return cell!
    }
}
