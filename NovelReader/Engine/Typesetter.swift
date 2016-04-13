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
    static let DEFAULT_MARGIN: UIEdgeInsets = UIEdgeInsetsMake(30, 25, 30, 25)
    
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
    func typeset(text: String, firstLineIsTitle: Bool = false, paperWidth: CGFloat = 0) -> NSMutableAttributedString {
        let attrt = NSMutableAttributedString(string: text)
        let yyFont = UIFont(name: FontManager.getFontName(font), size: self.fontSize)
        var start: Int = 0
        
        if firstLineIsTitle {
            let range = text.rangeOfString(FileReader.getNewLineCharater(text))
            
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
        
        attrt.yy_setFont(yyFont, range: NSMakeRange(start, attrt.length - start))
        attrt.yy_setAlignment(.Justified, range: NSMakeRange(start, attrt.length - start))

        attrt.yy_color = UIColor.blackColor()
        attrt.yy_lineSpacing = line_space

        return attrt
    }

    func makeFrame(content: String, bounds: CGRect)->CTFrameRef {
        var aligment        = CTTextAlignment.Justified
        var lineSpace       = line_space
        var paraSpace       = 0.0
        var lineBreak       = CTLineBreakMode.ByWordWrapping
        let settings        = [
            CTParagraphStyleSetting(spec: .Alignment, valueSize: sizeofValue(aligment), value: &aligment),
            CTParagraphStyleSetting(spec: .LineSpacing, valueSize: sizeofValue(lineSpace), value: &lineSpace),
            CTParagraphStyleSetting(spec: .LineBreakMode, valueSize: sizeofValue(lineBreak), value: &lineBreak),
            CTParagraphStyleSetting(spec: .ParagraphSpacing, valueSize: sizeofValue(paraSpace), value: &paraSpace),
        ]

        let attrContent = NSMutableAttributedString(string: content)
        let range       = NSMakeRange(0, attrContent.length)
        let style       = CTParagraphStyleCreate(settings, 5)

        attrContent.addAttribute(NSFontAttributeName, value: UIFont(name: FontManager.getFontName(font), size: self.fontSize)!, range: range)
        attrContent.addAttribute(NSForegroundColorAttributeName, value: UIColor.blackColor(), range: range)
        CFAttributedStringSetAttribute(attrContent, CFRangeMake(0, range.length), kCTParagraphStyleAttributeName, style)

        let frameSetter = CTFramesetterCreateWithAttributedString(attrContent as CFAttributedStringRef)
        let path        = CGPathCreateMutable()
        let container   = CGRectMake(
            bounds.origin.x + margin.left,
            bounds.origin.y + margin.top,
            bounds.size.width - margin.left - margin.right,
            bounds.size.height - margin.top - margin.bottom
        )

        CGPathAddRect(path, nil, container)
        return CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, range.length), path, nil)
    }
}
