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