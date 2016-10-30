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

    init(title: String = NO_TITLE, range: NSRange = EMPTY_RANGE) {
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
        return "\(title)\(range.desc)".hash
    }

    var rowId: Int = 0

    var fields: [Db.Field] {
        return [.TEXT(name: "Title", value: title),
                .INTEGER(name: "Location", value: range.loc),
                .INTEGER(name: "Length", value: range.len),
                .INTEGER(name: "Hash", value: hash)]
    }

    var table: String {
        return "Catalog"
    }

    func parse(row: [AnyObject]) -> Rowable {
        return BookMark(
            title: row[0] as? String ?? NO_TITLE,
            range: NSMakeRange(row[1] as? Int ?? 0, row[2] as? Int ?? 0)
        )
    }
}

func == (lhs: BookMark, rhs: BookMark) -> Bool {
    return lhs.range == lhs.range
}
