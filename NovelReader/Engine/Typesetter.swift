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
    
    /**
     * Default margin: (top, left, bottom, right)
     */
    static let DEFAULT_MARGIN: UIEdgeInsets = UIEdgeInsetsMake(20, 20, 20, 20)
    
    /*Default line space*/
    static let DEFAULT_LINE_SPACE: CGFloat = 10
    
    /*Default font*/
    static let DEFAULT_FONT = FontManager.SupportFonts.System
    
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
    
    /**
     * Paper border margin: (left, top, right, bottom)
     */
    var margin: UIEdgeInsets = Self.DEFAULT_MARGIN {
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
    func typeset(text: String, firstLineIsTitle: Bool = false, paperWidth: CGFloat = 0, startWithNewLine: Bool = false) -> NSMutableAttributedString {
        let attrt  = NSMutableAttributedString(string: text)
        let yyFont = UIFont(name: FontManager.getFontName(font), size: self.fontSize)
        var start  = 0
        let range  = text.rangeOfString(FileReader.getNewLineCharater(text))

        // Set style for chapter title
        if firstLineIsTitle {
            if let r = range {
                let titleFont = UIFont(name: FontManager.getFontName(font), size: self.fontSize + 10)
                start = text.substringToIndex(r.startIndex).length
                
                attrt.yy_setFont(titleFont, range: NSMakeRange(0, start))
                attrt.yy_setAlignment(.Natural, range: NSMakeRange(0, start))

                let line = UIView(frame: CGRectMake(0, 0, paperWidth - margin.left - margin.right, 1))
                line.backgroundColor = UIColor.blackColor()
                
                let lineStr = NSMutableAttributedString.yy_attachmentStringWithContent(
                    line,
                    contentMode: .Center,
                    attachmentSize: line.bounds.size,
                    alignToFont: yyFont, alignment: .Center)
                
                attrt.insertAttributedString(lineStr, atIndex: start)
            }
        }

        // Set indent for first line at paragraph
        if startWithNewLine {
            attrt.yy_firstLineHeadIndent = CGFloat(fontSize * 2)
        } else {
            if let r = range {
                let s = text.substringToIndex(r.startIndex).length
                attrt.yy_setFirstLineHeadIndent(CGFloat(fontSize * 2), range: NSMakeRange(s, attrt.length - s))
            }
        }

        attrt.yy_setFont(yyFont, range: NSMakeRange(start, attrt.length - start))
        attrt.yy_setAlignment(.Justified, range: NSMakeRange(start, attrt.length - start))

        attrt.yy_color            = UIColor.blackColor()
        attrt.yy_lineSpacing      = line_space
        attrt.yy_paragraphSpacing = line_space * 2
        return attrt
    }
}
