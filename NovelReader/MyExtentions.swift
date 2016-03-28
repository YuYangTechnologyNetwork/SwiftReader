//
//  NSExtendions.swift
//  NovelReader
//
//  Created by kangyonggen on 3/28/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

extension String {
    var length: Int {
        return characters.count
    }

    func regexMatch(regex: String) -> Bool {
        do {
            let exp = try NSRegularExpression(pattern: regex, options: .CaseInsensitive)
            return exp.matchesInString(self, options: .Anchored, range: NSMakeRange(0, length)).count > 0
        } catch _ {
            return false
        }
    }
}