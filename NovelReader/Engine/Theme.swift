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

    static var NIGHT: String { return "Night" }
    static var SEPIA: String { return "Sepia" }
    static var DEFAULT: String { return "Default" }
    static var PARCHMENT: String { return "Parchment" }
    static var EYESHIELD: String { return "Eyeshield" }

    var name: String {
        return Theme.DEFAULT
    }

    class Parchment: Theme {
        private static var bgColor: UIColor? = nil
        override var name: String { return Theme.PARCHMENT }

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
        override var name: String { return Theme.NIGHT }

        override init() {
            super.init()
            foregroundColor = UIColor(red: 0.310, green: 0.407, blue: 0.478, alpha: 1)
            backgroundColor = UIColor(red: 0.097, green: 0.129, blue: 0.158, alpha: 1)
        }
    }

    class Sepia: Theme {
        override var name: String { return Theme.SEPIA }

        override init() {
            super.init()
            foregroundColor = UIColor(red: 0.099, green: 0.031, blue: 0.006, alpha: 1)
            backgroundColor = UIColor(red: 0.798, green: 0.746, blue: 0.654, alpha: 1)
        }
    }

    class Eyeshield: Theme {
        override var name: String { return Theme.EYESHIELD }

        override init() {
            super.init()
            foregroundColor = UIColor(red: 0.167, green: 0.225, blue: 0.163, alpha: 1)
            backgroundColor = UIColor(red: 0.695, green: 0.822, blue: 0.710, alpha: 1)
        }
    }
}
