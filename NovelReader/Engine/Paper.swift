//
//  Paper.swift
//  NovelReader
//
//  Created by kangyonggen on 3/31/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

class Paper {
    var view: YYLabel!
    var text: NSMutableAttributedString? = nil

    init(size: CGRect) {
        self.view = YYLabel(frame: size)

        // Base
        view.numberOfLines = 0
        view.textColor = UIColor.blackColor()
        view.truncationToken = NSAttributedString(string: "")
        view.lineBreakMode = .ByWordWrapping

        let tys = Typesetter.Ins

        // Paper bound margin
        view.textContainerInset = UIEdgeInsetsMake(tys.margin.0, tys.margin.1, tys.margin.2, tys.margin.3)

        // Text direction
        view.verticalForm = tys.textOrentation == Typesetter.TextOrentation.Vertical
    }

    func attachText(text: String) -> NSRange {
        self.text = Typesetter.Ins.typeset(text)
        self.view.attributedText = self.text
        return self.view.textLayout.visibleRange
    }

    func getView() -> UIView {
        return self.view
    }
}