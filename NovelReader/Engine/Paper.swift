//
//  Paper.swift
//  NovelReader
//
//  Created by kangyonggen on 3/31/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

class Paper: NSObject {
    /*Visible text*/
    var text: String!

    /*For YYLabel*/
    private var textLayout: YYTextLayout!

    /*For YYLabel*/
    private let textContainer: YYTextContainer!

    private var rangeInFile: NSRange = EMPTY_RANGE

    /*paper's length in origin book file*/
    var realLen: Int = 0

    /*The first line is the paragraph start*/
    private(set) var endWithNewLine: Bool = false

    /*Paper text bounds*/
    private var size: CGSize!
    
    init(size: CGSize) {
        var paperMargin    = UIEdgeInsetsZero
        paperMargin.left   = Typesetter.Ins.margin.left
        paperMargin.top    = Typesetter.Ins.margin.top + Typesetter.Ins.line_space / 2
        paperMargin.right  = Typesetter.Ins.margin.right
        paperMargin.bottom = Typesetter.Ins.margin.bottom

        self.size                               = size
        self.textContainer                      = YYTextContainer(size: size, insets: paperMargin)
        self.textContainer.maximumNumberOfRows  = 0
        self.textContainer.verticalForm         = Typesetter.Ins.textOrentation == Typesetter.TextOrentation.Vertical
    }

    /**
     Use typesetter to write text to this paper line by line
     
     - parameter text:             Need writted to this paper
     - parameter firstLineIsTitle: First line is the chapter title?
     - parameter startWithNewLine: If started with new line, indent needed
     */
    func writtingLineByLine(text: String, firstLineIsTitle: Bool = false, startWithNewLine: Bool = false) {
        let newLineChar = FileReader.getNewLineCharater(text)
        let lines       = text.componentsSeparatedByString(newLineChar)

        // Split lines
        var reIndentText: String = ""
        for l in lines {
            let tl = l.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
            if tl.length > 0 {
                reIndentText += tl + newLineChar
            }
        }

        // Ignore empty paper
        if reIndentText.length == 0 {
            return
        }

        // Get the visible text
        var attrText   = Typesetter.Ins.typeset(reIndentText, firstLineIsTitle: firstLineIsTitle,
                                              paperWidth: size.width, startWithNewLine: startWithNewLine)
        var tmpTxtLy   = YYTextLayout(container: self.textContainer, text: attrText)
        let vRange     = tmpTxtLy!.visibleRange
        let vText      = attrText.attributedSubstringFromRange(vRange).string
        let vLines     = vText.componentsSeparatedByString(newLineChar)
        endWithNewLine = (vLines.last?.isEmpty)!
        self.realLen   = visibleLengthInOriginalText(text, visibleLines: vLines)

        if reIndentText.length > vText.length {
            let looseRange = NSMakeRange(vRange.loc, min(vRange.length + 20, reIndentText.length - vRange.loc))
            attrText       = Typesetter.Ins.typeset(attrText.attributedSubstringFromRange(looseRange).string,
                                              firstLineIsTitle: firstLineIsTitle,
                                              paperWidth: size.width, startWithNewLine: startWithNewLine)
            tmpTxtLy       = YYTextLayout(container: self.textContainer, text: attrText)
        }

        self.textLayout = tmpTxtLy
        self.text       = attrText.attributedSubstringFromRange(textLayout.visibleRange).string
    }
    
    /**
     Get the visible text end position in original text
     
     - parameter text:         The original text
     - parameter visibleLines: Visbile lines
     
     - returns: Int, the visible end position
     */
    private func visibleLengthInOriginalText(text: String, visibleLines: [String]) -> Int {
        var startIndex = text.startIndex
        for line in visibleLines {
            let range = text.rangeOfString(line, options: .CaseInsensitiveSearch,
                range: Range<String.Index>(startIndex ..< text.endIndex), locale: nil)
            
            if let r = range {
                startIndex = r.endIndex
            }
        }
        
        return text.substringToIndex(startIndex).length
    }

    /*
     * Attach this paper to a YYLabel to show
     *
     * @param           View to show paper
     *
     * @return Bool     If paper not call writtingText, false will be returned
     */
    func attachToView(yyLabel: YYLabel) -> Bool {
        if self.textLayout != nil {
            yyLabel.displaysAsynchronously = true
            yyLabel.ignoreCommonProperties = true
            yyLabel.textLayout             = self.textLayout;
            return true
        }
        
        return false
    }
}