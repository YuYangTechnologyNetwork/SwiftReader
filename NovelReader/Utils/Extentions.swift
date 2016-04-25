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

    var length: Int {
        return characters.count
    }

    func regexMatch(regex: String) -> Bool {
        do {
            let exp = try NSRegularExpression(pattern: regex, options: .AnchorsMatchLines)
            return exp.matchesInString(self, options: .WithoutAnchoringBounds, range: NSMakeRange(0, length)).count > 0
        } catch _ {
            return false
        }
    }

    func length(encoding: UInt) -> Int {
        return lengthOfBytesUsingEncoding(encoding)
    }

    func array() -> [Char] {
        return self.characters.map { String($0) }
    }

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
}

extension UIColor {
    static func hex(rgb: Int, alpha: CGFloat = 1) -> UIColor {
        return UIColor(red: CGFloat(rgb & 0xFF0000 >> 16) / 255.0, green: CGFloat(rgb & 0xFF00 >> 8) / 255.0,
            blue: CGFloat(rgb & 0xFF) / 255.0, alpha: alpha)
    }
}