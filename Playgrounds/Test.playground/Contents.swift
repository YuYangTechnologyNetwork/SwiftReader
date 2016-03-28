//: Playground - noun: a place where people can play

import Cocoa

var str = "Hello, playground"

var ptr = UnsafeMutablePointer<UInt8>.alloc(16)

for i in 0 ..< 16 {
    ptr[i] = UInt8(i + 10)
}

func printArray(arr:UnsafeMutablePointer<UInt8>, len:Int) {

    var str = String()
    for i in 0 ..< len {
        str += "\(arr[i]) "
    }

    print(str)
}

var tuple = (3,7)
switch tuple {

case (0...4,6...9):break
default:break
}

printArray(ptr, len: 16)

ptr += 1

printArray(ptr, len: 15)
