//: Playground - noun: a place where people can play

import UIKit

extension String {
    var len: Int {
        return characters.count
    }
}

extension NSInputStream {
    public func readBytes(length:Int)->UnsafeMutablePointer<UInt8>{
        let readBuffer = UnsafeMutablePointer<UInt8>.alloc(length + 1)
        let _          = self.read(readBuffer, maxLength: length)
        return readBuffer
    }
}

let ce2ne = {(ce:Any) -> NSStringEncoding in
    if let _ = ce as? CFIndex {
        return CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(ce as! CFIndex))
    } else if let _ = ce as? NSStringEncoding {
        return ce as! NSStringEncoding
    } else {
        return NSUTF8StringEncoding
    }
}

var supportEncodings:[Any] = [NSUTF8StringEncoding, CFStringEncodings.GB_18030_2000.rawValue]

func getFileEncoding(file:NSURL)->UInt {
    let ins     = NSInputStream(URL: file)
    
    ins?.open()
    let len     = 6
    let bytes   = ins?.readBytes(len)
    
    ins?.close()
    
    let str = String(bytesNoCopy: bytes!, length: len, encoding: ce2ne(supportEncodings[1]), freeWhenDone: true)
    
    print(str)
    
    return 0
}

var files  = [[#FileReference(fileReferenceLiteral: "jy_gbk.txt")#], [#FileReference(fileReferenceLiteral: "jy_utf8.txt")#]]

getFileEncoding(files[1])
