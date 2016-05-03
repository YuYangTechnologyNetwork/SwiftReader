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
    static func Log(anyObj: AnyObject?, file: String = #file, fun: String = #function, line: Int = #line) {
        #if DEBUG
            let paths = file.componentsSeparatedByString("/").last!.componentsSeparatedByString(".")
            let funcs = fun.componentsSeparatedByString("(")
            let anyOb = anyObj == nil ? "nil" : anyObj!
            NSLog("\(paths.first!).\(funcs.first!)(:\(line)) \(anyOb)")
        #endif
    }

    /**
     Create a UIImage from the color
     
     - parameter color:  UIColor
     - parameter size:   UIImage size
     - parameter circle: circle?
     
     - returns: A UIImage
     */
    static func color2Img(color: UIColor, size: CGSize, circle: Bool = false) -> UIImage {
        let layer = CALayer()
        layer.frame = CGRectMake(0, 0, size.width, size.height)
        layer.backgroundColor = color.CGColor
        layer.allowsEdgeAntialiasing = true
        
        if circle {
            layer.cornerRadius = min(size.width, size.height) / 2
            layer.masksToBounds = true
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let ctx = UIGraphicsGetCurrentContext()!
        CGContextSetInterpolationQuality(ctx, .High)
        layer.renderInContext(ctx)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return img
    }
}