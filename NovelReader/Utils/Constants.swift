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

class Constants {
    static let GLOBAL_ASYNC_QUEUE_NAME = "global_async_queue"
    
    static let NO_TITLE = "no_title"

    static let EMPTY_STR = ""
    static let EMPTY_RANGE = NSMakeRange(0, 0)
}