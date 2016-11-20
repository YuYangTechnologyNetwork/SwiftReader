//
//  BookMark.swift
//  NovelReader
//
//  Created by kang on 4/10/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

class BookMark: NSObject, Rowable {
    final class Columns {
        static let Title     = "Title"
        static let Location  = "Location"
        static let Length    = "Length"
        static let UniqueId  = "UniqueId"
    }
    
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
            return self.uniqueId == object?.uniqueId
        }

        return false
    }

    var uniqueId: String {
        return "\(title)\(range.desc)".md5()
    }

    var rowId: Int = 0

    var fields: [Db.Field] {
        return [.TEXT(name: Columns.Title, value: title),
                .INTEGER(name: Columns.Location, value: range.loc),
                .INTEGER(name: Columns.Length, value: range.len),
                .TEXT(name: Columns.UniqueId, value: uniqueId)]
    }

    var table: String {
        return "Catalog"
    }

    func parse(row: [AnyObject]) -> Rowable? {
        return BookMark(
            title: row[0] as? String ?? NO_TITLE,
            range: NSMakeRange(row[1] as? Int ?? 0, row[2] as? Int ?? 0)
        )
    }
}

func == (lhs: BookMark, rhs: BookMark) -> Bool {
    return lhs.range == lhs.range
}
