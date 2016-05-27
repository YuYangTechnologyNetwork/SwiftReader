//
//  NSExtendions.swift
//  NovelReader
//
//  Created by kangyonggen on 3/28/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

extension String {
    typealias Char = String
    typealias Index = String.CharacterView.Index

    var length: Int {
        return characters.count
    }

    /**
     Match with regex
     
     - parameter regex: The regex string
     
     - returns: Bool
     */
    func regexMatch(regex: String) -> Bool {
        do {
            let exp = try NSRegularExpression(pattern: regex, options: .AnchorsMatchLines)
            return exp.matchesInString(self, options: .WithoutAnchoringBounds, range: NSMakeRange(0, length)).count > 0
        } catch _ {
            return false
        }
    }

    /**
     Bytes length with the special NSStringEncoding
     
     - parameter encoding: NSStringEncdogin
     
     - returns: bytes length
     */
    func length(encoding: UInt) -> Int {
        return lengthOfBytesUsingEncoding(encoding)
    }

    /**
     String to Char array
     
     - returns: Array wrapped characters
     */
    func array() -> [Char] {
        return characters.map { String($0) }
    }

    func pickFirst(count: Int) -> String {
        return (self as NSString).substringToIndex(min(count, length - 1))
    }

    /**
     Calculate the similarity between self and othrer via LD(Levenshtein Distance) arithmetic
     
     - parameter another: Another string
     
     - returns: (Step, SimilarDegree)
     */
    func similarity(another: String) -> (Int, Float) {
        let str1 = self.array()
        let str2 = another.array()
        var dif: [[Int]] = []

        for i in 0 ... str1.count {
            var inner: [Int] = []

            for j in 0 ... str2.count {
                inner.append(i == 0 ? j : j == 0 ? i : 0)
            }

            dif.append(inner)
        }

        var temp = 0
        for i in 1 ..< dif.count {
            for j in 1 ..< dif[i].count {
                temp = str1[i - 1] == str2[j - 1] ? 0 : 1
                let m1 = min(dif[i - 1][j - 1] + temp, dif[i][j - 1] + 1)
                dif[i][j] = min(m1, dif[i - 1][j] + 1)
            }
        }

        let dis = dif[str1.count][str2.count]
        let sim = (1.0 - Float(dis) / Float(max(str1.count, str2.count)))
        
        return (dis, sim)
    }
}

extension NSRange {
    var end: Int {
        return location + length
    }
    
    var loc: Int {
        return location
    }
    
    var len: Int {
        return length
    }
    
    var desc: String {
        return String("\(loc)\(len)".hash)
    }

    var isLogical : Bool {
        return location < end
    }
}

extension UIEdgeInsets {
	mutating func increase(l: CGFloat, t: CGFloat, r: CGFloat, b: CGFloat) {
		self.top += t
		self.left += l
		self.right += r
		self.bottom += b
	}
    
	mutating func clamp(down: UIEdgeInsets, up: UIEdgeInsets) {
        self.top = min(up.top, max(self.top, down.top))
        self.left = min(up.left, max(self.left, down.left))
        self.right = min(up.right, max(self.right, down.right))
        self.bottom = min(up.bottom, max(self.bottom, down.bottom))
	}
}

extension UIColor {
    /**
     Hex int to UIColor, eg: #7FFFFF -> UIColor(r,g,b)
     
     - parameter rgb:   The hex color
     - parameter alpha: Alpha value
     
     - returns: UIColor
     */
    static func hex(rgb: Int, alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: CGFloat(rgb & 0xFF0000 >> 16) / 255.0, green: CGFloat(rgb & 0xFF00 >> 8) / 255.0,
            blue: CGFloat(rgb & 0xFF) / 255.0, alpha: alpha)
    }
    
    func newAlpha(alpha: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: r, green: g, blue: b, alpha: alpha)
    }
    
    func newBrightness(brightness: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s, brightness: brightness, alpha: a)
    }
}