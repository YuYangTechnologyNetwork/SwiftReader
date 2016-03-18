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
        let _ = self.read(readBuffer, maxLength: length)
        return readBuffer
    }
}

var filePath = [#FileReference(fileReferenceLiteral: "将夜.txt")#]
var utf8File = [#FileReference(fileReferenceLiteral: "UTF8.txt")#]

func getFileEncoding(file:NSURL)->UInt {
    var encoding:UInt = 0
    
    do {
        let fileHandler = try NSFileHandle(forReadingFromURL: file)
        fileHandler.seekToFileOffset(0)
        let data = fileHandler.readDataOfLength(10)
        
        var ins = NSInputStream(URL: file)
        ins?.open()
        var buffer = ins?.hasBytesAvailable
        
        var bytes = ins?.readBytes(3)
        var first = 0xa1
        bytes?[0]
        bytes?[1]
        bytes?[2]
        bytes?[3]
        
    } catch _ {
        
    }
    
    return encoding
}

getFileEncoding(filePath)
