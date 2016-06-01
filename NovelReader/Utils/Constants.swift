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
}

let NO_TITLE                   = "No_Title"
let EMPTY_STR                  = ""
let EMPTY_SIZE                 = CGSizeMake(0, 0)
let EMPTY_RANGE                = NSMakeRange(0, 0)
let CHAPTER_SIZE               = 15360
let BUILD_BOOK                 = "zx_utf8"
let READER_DEFAULT_ASYNC_QUEUE = "Reader_Default_Async_Queue"