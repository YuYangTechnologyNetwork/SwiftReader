//
//  Typesetter.swift
//  NovelReader
//
//  Created by kang on 3/14/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit
import YYText

class Typesetter {
    /*Text draw direction*/
    enum TextOrentation {
        case Horizontal
        case Vertical
    }

    enum Observer:String {
		case Font, FontSize, LineSpace, BorderMargin, TextOrentation, Theme, Brightness
    }
    
    private typealias `Self` = Typesetter

    static let DEFAULT_THEME = Theme.Default
    
    /*Default font size*/
    static let DEFAULT_FONT_SIZE: CGFloat = 18

    static let DEFAULT_BRIGHTNESS: CGFloat = 1
    
    static let FontSize_Min:CGFloat    = 12
    static let FontSize_Max:CGFloat    = 24
    static let Margin_Min:UIEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
    static let Margin_Max:UIEdgeInsets = UIEdgeInsetsMake(50, 50, 50, 50)
    static let LineSpace_Min:CGFloat   = 0
    static let LineSpace_Max:CGFloat   = 20
    
    /**
     * Default margin: (top, left, bottom, right)
     */
    static let DEFAULT_MARGIN: UIEdgeInsets = UIEdgeInsetsMake(30, 30, 30, 30)
    
    /*Default line space*/
    static let DEFAULT_LINE_SPACE: CGFloat = 12
    
    /*Default font*/
    static let DEFAULT_FONT = FontManager.SupportFonts.System
    
    /*Singleton*/
    static let Ins = Typesetter()
    private init() { }
    
    /*Property changed callbacks*/
    private var listeners: [String: (_: Observer, before:Any) -> Void] = [:]
    
    /*Font name code, see FontManager.SupportFonts*/
    var font: FontManager.SupportFonts = Self.DEFAULT_FONT {
        didSet { for l in listeners.values { l(.Font, before: oldValue) } }
    }
    
    /*Font size, for CGFloat type*/
    var fontSize: CGFloat = Self.DEFAULT_FONT_SIZE {
        didSet { for l in listeners.values { l(.FontSize, before: oldValue) } }
    }
    
    /*Line space, for CGFloat type*/
    var line_space: CGFloat = Self.DEFAULT_LINE_SPACE {
        didSet { for l in listeners.values { l(.LineSpace, before: oldValue) } }
    }
    
    /**
     * Paper border margin: (left, top, right, bottom)
     */
    var margin: UIEdgeInsets = Self.DEFAULT_MARGIN {
        didSet { for l in listeners.values { l(.BorderMargin, before: oldValue) } }
    }

    /*Text draw direction, see Typesetter.TextOrentation*/
    var textOrentation: TextOrentation = .Horizontal {
        didSet { for l in listeners.values { l(.TextOrentation, before: oldValue) } }
    }

    var theme: Theme = Self.DEFAULT_THEME {
        didSet {
            self.oldTheme = oldValue
            for l in listeners.values { l(.Theme, before: oldValue) }
        }
    }

    var brightness: CGFloat = Self.DEFAULT_BRIGHTNESS {
        didSet {
            brightness = min(1, max(0.3, brightness))
            for l in listeners.values { l(.Brightness, before: oldValue) }
        }
    }
    
    private(set) var oldTheme:Theme? = nil

    /*
     * Add the listener to observe Typesetter properties changed
     *
     * @param name          The added listener name, remove need it
     *
     * @param listener      Any property changed, listener will be called
     */
    func addListener(name: String, listener: (_: Observer, before:Any) -> Void) -> Typesetter {
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
    
    /**
     Typeset the text, return a attribute string
     
     - parameter text:             The need typeset text
     - parameter firstLineIsTitle: First line is chapter title?
     - parameter paperWidth:       Paper size
     - parameter startWithNewLine: If start with newline, indent is needed
     
     - returns: NSMutableAttributedString wrapped the typesetted text
     */
	func typeset(text: String, paperWidth: CGFloat, firstLineIsTitle: Bool, startWithNewLine: Bool,
		blinkSnipptes: [String] = [], notedSnipptes: [String] = []) -> NSMutableAttributedString {
        let attrt  = NSMutableAttributedString(string: text)
        let yyFont = self.font.forSize(self.fontSize)
        
        var start  = 0
        let range  = text.rangeOfString(FileReader.getNewLineCharater(text))

        // Set style for chapter title
        if firstLineIsTitle {
            if let r = range {
                let titleFont = self.font.forSize(self.fontSize + 10)
                start = text.substringToIndex(r.startIndex).length
                
                attrt.yy_setFont(titleFont, range: NSMakeRange(0, start))
                attrt.yy_setAlignment(.Natural, range: NSMakeRange(0, start))

                // Draw title and content split line
                let line = UIView(frame: CGRectMake(0, 0, paperWidth - margin.left - margin.right, 1))
                line.backgroundColor = theme.foregroundColor
                
                let lineStr = NSMutableAttributedString.yy_attachmentStringWithContent(
                    line,
                    contentMode: .Center,
                    attachmentSize: line.bounds.size,
                    alignToFont: yyFont, alignment: .Center)
                
                attrt.insertAttributedString(lineStr, atIndex: start)
            }
        }

        // Set indent for first line of paragraph
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

        // Set noted snipptes
        if !notedSnipptes.isEmpty {
            let nsStr           = attrt.string as NSString
            let yyBoard         = YYTextBorder()
            yyBoard.lineStyle   = [.PatternSolid, .Single]
            yyBoard.fillColor   = theme.styleLineColor
            yyBoard.strokeColor = theme.styleLineColor
            yyBoard.strokeWidth = 0.5
            yyBoard.insets      = UIEdgeInsetsMake(yyFont.capHeight * 2, 0, 0, 0)
            var searchRange     = NSMakeRange(0, nsStr.length)
            
            for l in notedSnipptes {
                if l.isEmpty || l.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet()).isEmpty {
                    continue
                }
                
                let r = nsStr.rangeOfString(l, options: .CaseInsensitiveSearch, range: searchRange)
                if r.length > 0 {
                    attrt.yy_setTextBorder(yyBoard, range: r)
                    searchRange = NSMakeRange(r.end, nsStr.length - r.end)
                }
            }
        }
        
        // Set blink snipptes
        if !blinkSnipptes.isEmpty {
            let nsStr            = attrt.string as NSString
            let yyBoard          = YYTextBorder()
            yyBoard.lineStyle    = [.PatternSolid, .Single]
            yyBoard.strokeWidth  = 1
            yyBoard.strokeColor  = theme.styleLineColor
            yyBoard.cornerRadius = yyFont.capHeight / 2
            yyBoard.insets       = UIEdgeInsetsMake(1, 0, 0, 0)
            var searchRange      = NSMakeRange(0, nsStr.length)
            
            for l in blinkSnipptes {
                if l.isEmpty || l.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet()).isEmpty {
                    continue
                }
                
                let r = nsStr.rangeOfString(l, options: .CaseInsensitiveSearch, range: searchRange)
                if r.length > 0 {
                    attrt.yy_setTextBorder(yyBoard, range: r)
                    searchRange = NSMakeRange(r.end, nsStr.length - r.end)
                }
            }
        }

        attrt.yy_color            = theme.foregroundColor
        attrt.yy_lineSpacing      = line_space
        attrt.yy_paragraphSpacing = line_space * 2
        return attrt
    }
}
