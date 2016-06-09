//
//  Themes.swift
//  NovelReader
//
//  Created by kyongen on 5/23/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import UIKit

enum Theme: Int {
    case Default = 0, Parchment, Eyeshield, Night

    private static var PBgColor: UIColor!

    var backgroundColor: UIColor {
        switch self {
        case .Default:
            return UIColor(red:0.986,  green:0.939,  blue:0.851, alpha:1)
        case .Eyeshield:
            return UIColor(red: 0.695, green: 0.822, blue: 0.710, alpha: 1)
        case .Night:
            return UIColor(red: 0.097, green: 0.129, blue: 0.158, alpha: 1)
        case .Parchment:
            if Theme.PBgColor == nil {
                let patch1 = UIImage(named: "reading_parchment1")
                let patch2 = UIImage(named: "reading_parchment2")
                let patch3 = UIImage(named: "reading_parchment3")
                let border = patch1!.size.width
                let size = CGSizeMake(border * 2, 2 * border)

                UIGraphicsBeginImageContext(size);
                patch1?.drawInRect(CGRectMake(0, 0, border, border))
                patch3?.drawInRect(CGRectMake(0, border, border, border))
                patch2?.drawInRect(CGRectMake(border, 0, border, border))
                patch1?.drawInRect(CGRectMake(border, border, border, border))
                Theme.PBgColor = UIColor(patternImage: UIGraphicsGetImageFromCurrentImageContext())
            }

            return Theme.PBgColor
        }
    }

    var menuBackgroundColor: UIColor {
        switch self {
        case .Parchment:
            return UIColor(red: 0.780, green: 0.633, blue: 0.455, alpha: 1)
        default:
            return backgroundColor
        }
    }

    var boardMaskNeeded: Bool {
        return self == .Parchment
    }

    var foregroundColor: UIColor {
        switch self {
        case .Default:
            return UIColor(red:0.355,  green:0.275,  blue:0.211, alpha:1)
        case .Eyeshield:
            return UIColor(red: 0.117, green: 0.143, blue: 0.113, alpha: 1)
        case .Parchment:
            return UIColor.blackColor()
        case .Night:
            return UIColor(red: 0.310, green: 0.407, blue: 0.478, alpha: 1)
        }
    }

    var highlightColor: UIColor {
        return UIColor(red:0.917,  green:0.360,  blue:0, alpha:0.6)
    }

    var isNight: Bool {
        return self == .Night
    }
}
