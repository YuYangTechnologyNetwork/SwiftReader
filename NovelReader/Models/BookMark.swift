//
//  BookMark.swift
//  NovelReader
//
//  Created by kang on 4/10/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

class BookMark: NSObject, Rowable {
    var title: String = NO_TITLE
    var range: NSRange = EMPTY_RANGE

    init(title: String = NO_TITLE, range: NSRange) {
        self.title = title
        self.range = range
    }

    override var description: String {
        return "\(title)(\(range.loc),\(range.end),\(range.len))"
    }

    override func isEqual(object: AnyObject?) -> Bool {
        if ((object as? BookMark) != nil) {
            return self.hash == object?.hash
        }

        return false
    }

    override var hash: Int {
        return "\(title)\(range)".hash
    }

    func values() -> [AnyObject] {
        return [title, range.loc, range.len, hash]
    }
}