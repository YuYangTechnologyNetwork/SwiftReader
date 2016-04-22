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
        paperMargin.bottom = Typesetter.Ins.margin.bottom + Typesetter.Ins.line_space / 2

        self.size                               = size
        self.textContainer                      = YYTextContainer(size: size, insets: paperMargin)
        self.textContainer.maximumNumberOfRows  = 0
        self.textContainer.verticalForm         = Typesetter.Ins.textOrentation == Typesetter.TextOrentation.Vertical
    }

    /*
     * Use typesetter to write text to this paper
     * 
     * @param text          A long String, Paper's text will be setted, len(Paper.text) <= text
     *
     * @return Paper        For the call chains
     */
    func writting(text: String, firstLineIsTitle: Bool = false) -> Paper {
        let attrt = Typesetter.Ins.typeset(text, firstLineIsTitle: firstLineIsTitle, paperWidth: size.width)
        self.textLayout = YYTextLayout(container: self.textContainer, text: attrt)
        self.text =  attrt.attributedSubstringFromRange(textLayout.visibleRange).string
        self.realLen = self.text.length
        return self
    }

    /*
     * Use typesetter to write text to this paper line by line
     *
     * @param text          A long String, Paper's text will be setted, len(Paper.text) <= text
     *
     * @return Paper        For the call chains
     */
    func writtingLineByLine(text: String, firstLineIsTitle: Bool = false, startWithNewLine: Bool = false) -> Paper {
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
            return self
        }

        // Get the visible text
        var attrText = Typesetter.Ins.typeset(reIndentText, firstLineIsTitle: firstLineIsTitle,
                                              paperWidth: size.width, startWithNewLine: startWithNewLine)
        var tmpTxtLy = YYTextLayout(container: self.textContainer, text: attrText)
        let vRange   = tmpTxtLy.visibleRange
        let vText    = attrText.attributedSubstringFromRange(vRange).string
        let vLines   = vText.componentsSeparatedByString(newLineChar)
        var lastT    = vLines.last!
        var endLen   = vLines.last!.length

        if endLen == 0 {
            lastT = vLines[vLines.count - 2]
            endLen += lastT.length
            endWithNewLine = true
        }

        let r = text.rangeOfString(lastT, options: .CaseInsensitiveSearch,
            range: Range<String.CharacterView.Index>(text.startIndex ..< text.endIndex), locale: nil)

        self.realLen = text.substringToIndex((r?.startIndex)!).length + endLen

        if reIndentText.length > vText.length {
            let looseRange = NSMakeRange(vRange.loc, min(vRange.length + 20, reIndentText.length - vRange.loc))
            attrText       = Typesetter.Ins.typeset(attrText.attributedSubstringFromRange(looseRange).string,
                                              firstLineIsTitle: firstLineIsTitle,
                                              paperWidth: size.width, startWithNewLine: startWithNewLine)

            tmpTxtLy       = YYTextLayout(container: self.textContainer, text: attrText)
        }

        self.textLayout = tmpTxtLy
        self.text       = attrText.attributedSubstringFromRange(textLayout.visibleRange).string

        return self
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