//
//  BookMark.swift
//  NovelReader
//
//  Created by kang on 4/10/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

class BookMark: NSObject {
    var title: String  = Constants.NO_TITLE
    var range: NSRange = Constants.EMPTY_RANGE
    var offset: UInt   = 0

    init(title: String, range: NSRange) {
        self.title = title
        self.range = range
    }
    
    override var description: String {
        return "\(title)\(range)"
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
}