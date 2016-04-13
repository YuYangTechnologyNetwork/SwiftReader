//
//  BoardView.swift
//  NovelReader
//
//  Created by kang on 4/12/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

class BoardView: UIView {
    private var textFrame:CTFrameRef?

    override func drawRect(rect: CGRect) {
        if let f = textFrame {
            let ctx = UIGraphicsGetCurrentContext();
            CGContextSetTextMatrix(ctx, CGAffineTransformIdentity)
            CGContextTranslateCTM(ctx, 0, self.bounds.size.height)
            CGContextScaleCTM(ctx, 1.0, -1.0)
            CTFrameDraw(f, ctx!)
        }
    }

    func pastePaper(paper: Paper) {
        textFrame = paper.textFrame
        self.setNeedsDisplay()
    }
}