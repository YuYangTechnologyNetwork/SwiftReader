//
//  Utils.swift
//  NovelReader
//
//  Created by kang on 4/23/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

class Utils {
    /**
     Control your log an DEBUG and RELEASE
     
     - parameter anyObj: any info
     - parameter file:   Logging file name
     - parameter fun:    Logging function name
     - parameter line:   Logging line
     */
    static func Log(anyObj: AnyObject, file: String = #file, fun: String = #function, line: Int = #line) {
        #if DEBUG
            let paths = file.componentsSeparatedByString("/")
            let funcs = fun.componentsSeparatedByString("(")
            NSLog("\(paths.last!)#\(funcs.first!)(:\(line))> \(anyObj)")
        #endif
    }
}