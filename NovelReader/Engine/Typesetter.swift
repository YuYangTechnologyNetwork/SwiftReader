//
//  Typesetter.swift
//  NovelReader
//
//  Created by kang on 3/14/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit

public class Typesetter: NSObject {
    struct Margin {
		var top: Int? , left : Int? , right : Int? , bottom : Int?
	}

    var font: UIFont?
	var line_space : CGFloat?

	override init()
	{
        font       = UIFont.systemFontOfSize(14.0)
        line_space = 8.0
	}

	init(config : String)
	{
        
	}

    func buildParagraphStyle() -> NSParagraphStyle {
        let paragraphStyle           = NSMutableParagraphStyle()
        paragraphStyle.alignment     = .Justified
        paragraphStyle.lineSpacing   = line_space!

        return paragraphStyle
    }

    func typesettingText(text: String) -> NSMutableAttributedString {
        let attrText     = NSMutableAttributedString(string: text)
        attrText.yy_font = font

        attrText.yy_setParagraphStyle(buildParagraphStyle(), range: NSMakeRange(0, attrText.length))

        return attrText
    }
}
