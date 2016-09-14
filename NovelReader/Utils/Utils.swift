//
//  Utils.swift
//  NovelReader
//
//  Created by kang on 4/23/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

final class Utils {
    /**
     Control your log for DEBUG and RELEASE
     
     - parameter anyObj: any info
     - parameter file:   Logging file name
     - parameter fun:    Logging function name
     - parameter line:   Logging line
     */
    static func Log(anyObj: Any?, file: String = #file, fun: String = #function, line: Int = #line) {
        #if DEBUG
            let paths = file.componentsSeparatedByString("/").last!.componentsSeparatedByString(".")
            let funcs = fun.componentsSeparatedByString("(")
            let anyOb = anyObj == nil ? "nil" : anyObj!
            NSLog("\(paths.first!).\(funcs.first!)(:\(line)) \(anyOb)")
        #endif
    }

    /**
     Create a UIImage from UIColor
     
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
        
        return img!
    }
    
    /**
     Convenient for dispatch async
     
     - parameter task: This closure will run on background thread
     - parameter main: This closure will run on main thread
     */
	static func asyncTask<T>(task: () -> T, onMain main: (res: T) -> Void) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
			let result = task()
			dispatch_async(dispatch_get_main_queue()) {
				main(res: result)
			}
		}
	}
    
    /**
     Convenient for dispatch async to execute UI task
     
     - parameter task: This closure will run on main thread
     */
	static func runUITask(task: () -> Void) {
		dispatch_async(dispatch_get_main_queue()) {
			task()
		}
	}
}
