//
//  Paper.swift
//  NovelReader
//
//  Created by kangyonggen on 3/31/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation
import YYText

class Paper: Equatable {
    
    struct Properties:Equatable {
        private(set) var needReformatPaper: Bool = false
        private(set) var startWithNewLine: Bool = false
        private(set) var endedWithNewLine: Bool = false
        
        private(set) var blinkSnipptes: [String] = [] {
			didSet {
				needReformatPaper = oldValue != blinkSnipptes
			}
		}

		private(set) var notedSnipptes: [String] = [] {
			didSet {
				needReformatPaper = oldValue != notedSnipptes
			}
		}
        
		private(set) var applyTheme: Theme! {
			didSet {
				needReformatPaper = applyTheme != nil && oldValue != applyTheme
			}
		}
	}
    
    private(set) var realLen: Int
    private(set) var text: String!
    private(set) var properties:Properties!
    private(set) var firstLineText: String?
    
    private var size: CGSize!
    private var cachedText:String!
    private var textLayout: YYTextLayout!
    private let textContainer: YYTextContainer!
    private var firstLineIsTitle:Bool!
    
    init(size: CGSize) {
        var paperMargin                        = UIEdgeInsetsZero
        paperMargin.left                       = Typesetter.Ins.margin.left
        paperMargin.top                        = Typesetter.Ins.margin.top + Typesetter.Ins.line_space / 2
        paperMargin.right                      = Typesetter.Ins.margin.right
        paperMargin.bottom                     = Typesetter.Ins.margin.bottom

        self.size                              = size
        self.realLen                           = 0
        self.properties                        = Properties()
        self.textContainer                     = YYTextContainer(size: size, insets: paperMargin)
        self.textContainer.verticalForm        = Typesetter.Ins.textOrentation == Typesetter.TextOrentation.Vertical
        self.textContainer.maximumNumberOfRows = 0
    }
    
	init(paper: Paper) {
        self.size                              = paper.size
        self.text                              = paper.text
        self.cachedText                        = paper.cachedText
        self.realLen                           = paper.realLen
        self.properties                        = paper.properties
        self.firstLineText                     = paper.firstLineText
        self.firstLineIsTitle                  = paper.firstLineIsTitle
        self.textContainer                     = YYTextContainer(size: size, insets: paper.textContainer.insets)
        self.textContainer.verticalForm        = Typesetter.Ins.textOrentation == Typesetter.TextOrentation.Vertical
        self.textContainer.maximumNumberOfRows = paper.textContainer.maximumNumberOfRows
        self.textLayout                        = YYTextLayout(container: textContainer, text: paper.textLayout.text)
	}
    
	func blink(snippets: [String] = []) -> Paper {
		properties.blinkSnipptes = snippets
		return self
	}

	func noted(snippets: [String] = []) -> Paper {
		properties.notedSnipptes = snippets
		return self
	}
    
	func applyTheme() -> Paper {
		properties.applyTheme = Typesetter.Ins.theme
		return self
	}
    
    func applyFormat() -> Paper {
        properties.needReformatPaper = true
        return self
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
        var attrText = Typesetter.Ins.typeset(
            reIndentText,
            paperWidth: size.width,
            firstLineIsTitle: firstLineIsTitle,
            startWithNewLine: startWithNewLine
        )

        var tmpTxtLy = YYTextLayout(container: self.textContainer, text: attrText)
        let vRange   = tmpTxtLy!.visibleRange
        let vText    = attrText.attributedSubstringFromRange(vRange).string
        let vLines   = vText.componentsSeparatedByString(newLineChar)

        if reIndentText.length > vText.length {
            let scope = NSMakeRange(vRange.loc, min(vRange.length + 20, attrText.length - vRange.loc))
            attrText  = Typesetter.Ins.typeset(
                attrText.attributedSubstringFromRange(scope).string,
                paperWidth: size.width,
                firstLineIsTitle: firstLineIsTitle,
                startWithNewLine: startWithNewLine
            )

            tmpTxtLy  = YYTextLayout(container: self.textContainer, text: attrText)
        }
        
        self.properties.startWithNewLine = startWithNewLine
        self.properties.endedWithNewLine = vLines.last!.isEmpty
        self.properties.applyTheme       = Typesetter.Ins.theme
        
        self.firstLineIsTitle     = firstLineIsTitle
        self.cachedText           = attrText.string
        self.textLayout           = tmpTxtLy
        self.realLen              = visibleLengthInOriginalText(text, visibleLines: vLines)
        self.firstLineText        = vLines.first
        self.text                 = attrText.attributedSubstringFromRange(textLayout.visibleRange).string
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
    
    /**
     Attach this paper to a YYLabel to show

     - parameter yyLabel:    View to show paper
     - parameter applyTheme: Theme changed or not
     */
    func attachToView(yyLabel: YYLabel) {
		if self.textLayout != nil {
			if properties.needReformatPaper && !cachedText.isEmpty {
                let attrText = Typesetter.Ins.typeset(
                    cachedText,
                    paperWidth: size.width,
                    firstLineIsTitle: firstLineIsTitle,
                    startWithNewLine: properties.startWithNewLine,
                    blinkSnipptes: properties.blinkSnipptes,
                    notedSnipptes: properties.notedSnipptes
                )
                
                var paperMargin                  = UIEdgeInsetsZero
                paperMargin.left                 = Typesetter.Ins.margin.left
                paperMargin.top                  = Typesetter.Ins.margin.top + Typesetter.Ins.line_space / 2
                paperMargin.right                = Typesetter.Ins.margin.right
                paperMargin.bottom               = Typesetter.Ins.margin.bottom

                self.textContainer.insets        = paperMargin
                self.textLayout                  = YYTextLayout(container: textContainer, text: attrText)
                self.properties.needReformatPaper = false
            }

			yyLabel.textLayout = self.textLayout;
		}
	}
}

func == (lhs: Paper.Properties, rhs: Paper.Properties) -> Bool {
	return lhs.endedWithNewLine == lhs.endedWithNewLine && lhs.startWithNewLine == lhs.startWithNewLine &&
	lhs.blinkSnipptes == rhs.blinkSnipptes && lhs.notedSnipptes == rhs.notedSnipptes
}

func == (lhs: Paper, rhs: Paper) -> Bool {
	return lhs.textLayout?.text == rhs.textLayout?.text && lhs.properties == rhs.properties
}