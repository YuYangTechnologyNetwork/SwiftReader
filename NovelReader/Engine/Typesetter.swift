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
    static let DEFAULT_FONT_SIZE: CGFloat = 20.0

    /*Default margin: (left, top, right, bottom)*/
    static let DEFAULT_MARGIN = (10, 8, 10, 8)

    /*Singleton*/
    static let Ins = Typesetter()
    private init() { }

    /*Property changed callbacks*/
    private var listeners: [String: (_: String) -> Void] = [:]

    /*Font name code, see FontManager.SupportFonts*/
    var font: FontManager.SupportFonts = FontManager.SupportFonts.System {
        didSet { for l in listeners.values { l("FontName") } }
    }

    /*Font size, for CGFloat type*/
    var fontSize: CGFloat = Self.DEFAULT_FONT_SIZE {
        didSet { for l in listeners.values { l("FontSize") } }
    }

    /*Line space, for CGFloat type*/
    var line_space: CGFloat = 8.0 {
        didSet { for l in listeners.values { l("LineSpace") } }
    }

    /*Paper border margin: (left, top, right, bottom)*/
    var margin: (CGFloat, CGFloat, CGFloat, CGFloat) = (8, 8, 8, 8) {
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
        let style = NSMutableParagraphStyle()

        attrt.yy_font = UIFont(name: FontManager.getFontName(font), size: self.fontSize)
        style.alignment = .Justified
        style.lineSpacing = line_space

        attrt.yy_setParagraphStyle(style, range: NSMakeRange(0, attrt.length))

        return attrt
    }
}
