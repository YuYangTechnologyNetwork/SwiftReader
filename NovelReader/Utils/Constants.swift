//
//  Error.swift
//  NovelReader
//
//  Created by kangyonggen on 3/29/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

enum Error: ErrorType {
    case FileNotExist(String)
    case NotSupportEncoding(String)
    case ClassInitFailure(String)
}

let CODE_TEST                  = false
let NO_TITLE                   = "No_Title"
let EMPTY_STR                  = ""
let EMPTY_SIZE                 = CGSizeMake(0, 0)
let EMPTY_RANGE                = NSMakeRange(0, 0)
let CHAPTER_SIZE               = 30720
let BUILD_BOOK                 = "zx_utf8"// "jy_gbk"
let READER_DEFAULT_ASYNC_QUEUE = "Reader_Default_Async_Queue"

class Config {
    class Db {
        static let DefaultDB = "NovelReader"
        static let Table_Bookshelf = "Bookshelf"
    }
}
