//
//  Typesetter.swift
//  NovelReader
//
//  Created by kang on 3/14/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit

class Typesetter {
    /*Text draw direction*/
    enum TextOrentation {
        case Horizontal
        case Vertical
    }

    private typealias `Self` = Typesetter

    /*Default font size*/
    static let DEFAULT_FONT_SIZE: CGFloat = 20

    /*Default margin: (top, left, bottom, right)*/
    static let DEFAULT_MARGIN: (CGFloat, CGFloat, CGFloat, CGFloat) = (20, 15, 20, 15)

    /*Default line space*/
    static let DEFAULT_LINE_SPACE: CGFloat = 0

    /*Default font*/
    static let DEFAULT_FONT = FontManager.SupportFonts.KaiTi

    /*Singleton*/
    static let Ins = Typesetter()
    private init() { }

    /*Property changed callbacks*/
    private var listeners: [String: (_: String) -> Void] = [:]

    /*Font name code, see FontManager.SupportFonts*/
    var font: FontManager.SupportFonts = Self.DEFAULT_FONT {
        didSet { for l in listeners.values { l("FontName") } }
    }

    /*Font size, for CGFloat type*/
    var fontSize: CGFloat = Self.DEFAULT_FONT_SIZE {
        didSet { for l in listeners.values { l("FontSize") } }
    }

    /*Line space, for CGFloat type*/
    var line_space: CGFloat = Self.DEFAULT_LINE_SPACE {
        didSet { for l in listeners.values { l("LineSpace") } }
    }

    /*Paper border margin: (left, top, right, bottom)*/
    var margin: (CGFloat, CGFloat, CGFloat, CGFloat) = Self.DEFAULT_MARGIN {
        didSet { for l in listeners.values { l("BorderMargin") } }
    }

    /*Text draw direction, see Typesetter.TextOrentation*/
    var textOrentation: TextOrentation = .Horizontal {
        didSet { for l in listeners.values { l("TextOrentation") } }
    }

    /*
     * Add the listener to observe Typesetter properties changed
     *
     * @param name          The added listener name, remove need it
     *
     * @param listener      Any property changed, listener will be called
     */
    func addListener(name: String, listener: (_: String) -> Void) -> Typesetter {
        if listeners.indexForKey(name) == nil {
            listeners[name] = listener
        }

        return self
    }

    /*
     * Remove listener by name

     * @param name          The name is setted via addListener func
     **/
    func removeListener(name: String) -> Typesetter {
        if listeners.indexForKey(name) != nil {
            listeners.removeValueForKey(name)
        }

        return self
    }

    /*
     * Typeset the text, return a attribute string
     *
     * @param text          The need typeset text
     *
     * @return NSMutableAttributedString the typesetted text
     */
    func typeset(text: String) -> NSMutableAttributedString {
        let attrt = NSMutableAttributedString(string: text)

        attrt.yy_font          = UIFont(name: FontManager.getFontName(font), size: self.fontSize)
        attrt.yy_color         = UIColor.blackColor()
        attrt.yy_lineBreakMode = .ByWordWrapping
        attrt.yy_alignment     = .Justified
        attrt.yy_lineSpacing   = line_space

        return attrt
    }
}
