//
//  Paper.swift
//  NovelReader
//
//  Created by kangyonggen on 3/31/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

class Paper: NSObject, YYTextLinePositionModifier {

    /*Visible text*/
    var text: String!

    /*For YYLabel*/
    private var textLayout: YYTextLayout!

    /*For YYLabel*/
    private let textContainer: YYTextContainer!

    /*Paper text bounds*/
    private var size: CGSize!
    
    init(size: CGSize) {
        self.size                               = size
        self.textContainer                      = YYTextContainer(size: size, insets: Typesetter.Ins.margin)
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
        self.textContainer.linePositionModifier = self
        self.textLayout = YYTextLayout(container: self.textContainer, text: attrt)
        self.text =  attrt.attributedSubstringFromRange(textLayout.visibleRange).string
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

    @objc func modifyLines(lines: [AnyObject]!, fromText text: NSAttributedString!, inContainer container: YYTextContainer!) {
    }

    @objc func copyWithZone(zone: NSZone) -> AnyObject {
        return Paper(size: size)
    }
}