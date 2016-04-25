//
//  Theme.swift
//  NovelReader
//
//  Created by kangyonggen on 3/31/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

class Theme {
    private(set) var foregroundColor: UIColor = UIColor.blackColor()
    private(set) var backgroundColor: UIColor = UIColor.whiteColor()
    private(set) var boardMaskNeeded: Bool = false

    class Parchment: Theme {
        private static var bgColor: UIColor? = nil

        override init() {
            super.init()
            foregroundColor = UIColor.blackColor()
            boardMaskNeeded = true

            if let bgc = Parchment.bgColor {
                foregroundColor = bgc
            } else {
                var parchment: dispatch_once_t = 0
                dispatch_once(&parchment) {
                    let patch1 = UIImage(named: "reading_parchment1")
                    let patch2 = UIImage(named: "reading_parchment2")
                    let patch3 = UIImage(named: "reading_parchment3")
                    let border = (patch1?.size.width)!
                    let size = CGSizeMake(border * 2, 2 * border)

                    UIGraphicsBeginImageContext(size);
                    patch1?.drawInRect(CGRectMake(0, 0, border, border))
                    patch3?.drawInRect(CGRectMake(0, border, border, border))
                    patch2?.drawInRect(CGRectMake(border, 0, border, border))
                    patch1?.drawInRect(CGRectMake(border, border, border, border))

                    self.backgroundColor = UIColor(patternImage: UIGraphicsGetImageFromCurrentImageContext())
                    Parchment.bgColor = self.backgroundColor
                }
            }
        }
    }

    class Night: Theme {
        override init() {
            super.init()
            foregroundColor = UIColor(red:0.310,  green:0.407,  blue:0.478, alpha:1)
            backgroundColor = UIColor(red:0.097,  green:0.129,  blue:0.158, alpha:1)
        }
    }

    class Sepia: Theme {
        override init() {
            super.init()
            backgroundColor = UIColor(red:0.973,  green:0.946,  blue:0.891, alpha:1)
        }
    }
}
