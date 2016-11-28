//
//  Typesetter.swift
//  NovelReader
//
//  Created by kang on 3/14/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit
import YYText

class Typesetter: NSObject, NSCoding  {
    /*Text draw direction*/
    enum TextOrientation:String {
        case Horizontal
        case Vertical
    }
    
    enum Observer:String {
        case Font, FontSize, LineSpace, BorderMargin, TextOrientation, Theme, Brightness
    }
    
    private typealias `Self` = Typesetter
    
    static let DEFAULT_THEME = Theme.Parchment
    
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
    static private(set) var Ins = Typesetter()
    @objc private override init() { super.init() }
    
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
    
    /*Text draw direction, see Typesetter.TextOrientation*/
    var textOrientation: TextOrientation = .Horizontal {
        didSet { for l in listeners.values { l(.TextOrientation, before: oldValue) } }
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
     
     - returns: NSMutableAttributedString wrapped the typed text
     */
    func typeset(text: String, paperWidth: CGFloat, firstLineIsTitle: Bool, startWithNewLine: Bool,
                 blinkSnippets: [String] = [], notedSnippets: [String] = []) -> NSMutableAttributedString {
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
        
        // Set noted snippets
        if !notedSnippets.isEmpty {
            let nsStr           = attrt.string as NSString
            let yyBoard         = YYTextBorder()
            yyBoard.lineStyle   = [.PatternSolid, .Single]
            yyBoard.fillColor   = theme.highlightColor
            yyBoard.strokeColor = theme.highlightColor
            yyBoard.strokeWidth = 0.5
            yyBoard.insets      = UIEdgeInsetsMake(yyFont.capHeight * 2, 0, 0, 0)
            var searchRange     = NSMakeRange(0, nsStr.length)
            
            for l in notedSnippets {
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
        
        // Set blink snippets
        if !blinkSnippets.isEmpty {
            let nsStr            = attrt.string as NSString
            let yyBoard          = YYTextBorder()
            yyBoard.lineStyle    = [.PatternSolid, .Single]
            yyBoard.strokeWidth  = 1
            yyBoard.strokeColor  = theme.highlightColor
            yyBoard.cornerRadius = yyFont.capHeight / 2
            yyBoard.insets       = UIEdgeInsetsMake(1, 0, 0, 0)
            var searchRange      = NSMakeRange(0, nsStr.length)
            
            for l in blinkSnippets {
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
    
    @objc func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.font.rawValue, forKey: Observer.Font.rawValue)
        aCoder.encodeDouble((Double)(self.fontSize), forKey: Observer.FontSize.rawValue)
        aCoder.encodeDouble((Double)(self.line_space), forKey: Observer.LineSpace.rawValue)
        aCoder.encodeUIEdgeInsets(self.margin, forKey: Observer.BorderMargin.rawValue)
        aCoder.encodeObject(self.textOrientation.rawValue, forKey: Observer.TextOrientation.rawValue)
        aCoder.encodeInteger(self.theme.rawValue, forKey: Observer.Theme.rawValue)
        aCoder.encodeDouble((Double)(self.brightness), forKey: Observer.Brightness.rawValue)
    }
    
    @objc required init?(coder aDecoder: NSCoder) {
        super.init()

        self.font = FontManager.SupportFonts(
            rawValue: aDecoder.decodeObjectForKey(Observer.Font.rawValue) as? String ?? Self.DEFAULT_FONT.rawValue)!
        self.fontSize = (CGFloat)(aDecoder.decodeDoubleForKey(Observer.FontSize.rawValue))
        self.line_space = (CGFloat)(aDecoder.decodeDoubleForKey(Observer.LineSpace.rawValue))
        self.margin = aDecoder.decodeUIEdgeInsetsForKey(Observer.BorderMargin.rawValue)
        self.textOrientation = TextOrientation(
            rawValue: aDecoder.decodeObjectForKey(Observer.TextOrientation.rawValue) as? String ??
                TextOrientation.Horizontal.rawValue)!
        self.theme = Theme(rawValue: aDecoder.decodeIntegerForKey(Observer.Theme.rawValue))!
        self.brightness = (CGFloat)(aDecoder.decodeDoubleForKey(Observer.Brightness.rawValue))
    }
    
    func save() {
        let user = NSUserDefaults.standardUserDefaults()
        user.setObject(NSKeyedArchiver.archivedDataWithRootObject(self), forKey: "Typesetter")
    }
    
    static func restore() {
        let user = NSUserDefaults.standardUserDefaults()
        let nsdt = user.objectForKey("Typesetter") as? NSData
        
        if let nd = nsdt {
            let tp = NSKeyedUnarchiver.unarchiveObjectWithData(nd) as? Typesetter
            
            if let t = tp {
                Typesetter.Ins = t
            }
        }
    }
}
