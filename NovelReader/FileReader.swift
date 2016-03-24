//
//  FileReader.swift
//  NovelReader
//
//  Created by kangyonggen on 3/21/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

class FileReader {
    private typealias `Self` = FileReader
    static let BUFFER_SIZE        = 65536
    static let UNKNOW_ENCODING    = "Unknow"
    static let ENCODING_UTF8      = "UTF-8"
    static let ENCODING_GB18030   = "GB18030"

    // Support encodings
    static let Encodings:[String:UInt32] = [
        ENCODING_UTF8: UInt32(NSUTF8StringEncoding),
        ENCODING_GB18030 : CFStringConvertNSStringEncodingToEncoding(UInt(CFStringEncodings.GB_18030_2000.rawValue))
    ]

    func guessFileEncoding(file: UnsafeMutablePointer<FILE>) -> String
    {
        // let start        = NSDate().timeIntervalSince1970
        let uchar_handle = uchardet_new()
        let cache_buffer = UnsafeMutablePointer<Int8>.alloc(Self.BUFFER_SIZE)

        while feof(file) == 0 {
            let valid_len = fread(cache_buffer, 1, Self.BUFFER_SIZE, file)
            let retval    = uchardet_handle_data(uchar_handle, cache_buffer, valid_len)

            if retval != 0 {
                return Self.UNKNOW_ENCODING
            }
        }

        uchardet_data_end(uchar_handle)

        let possible_encoding = String.fromCString(uchardet_get_charset(uchar_handle))

        uchardet_delete(uchar_handle)

        // print("Usage Time: \(NSDate().timeIntervalSince1970 - start)")

        return isSupportEncding(possible_encoding!) ? possible_encoding! : Self.UNKNOW_ENCODING
    }

    func isSupportEncding(encoding: String) -> Bool
    {
        return Self.Encodings.indexForKey(encoding) != nil;
    }

    func getWordBorder(file:UnsafeMutablePointer<FILE>, fuzzyPos:Int, encoding:UInt32) -> Int {
        var lastPost:fpos_t = 0
        var valid_pos = -1
        fgetpos(file, &lastPost)
        fseek(file, fuzzyPos, SEEK_SET)

        switch encoding {
        case Self.Encodings[Self.ENCODING_UTF8]!:
            let utf_buffer = UnsafeMutablePointer<UInt8>.alloc(6)
            let valid_len  = fread(utf_buffer, 1, 6, file)

            if valid_len == 6 {
                for i in 0...5 {
                    if utf_buffer[i] & 0x80 == 0 || utf_buffer[i] & 0xc0 == 0xc0 {
                        valid_pos = fuzzyPos + i
                        break
                    }
                }
            } else if feof(file) == 0 {
                valid_pos = fuzzyPos + valid_len
            }
            break
        case Self.Encodings[Self.ENCODING_GB18030]!:
            
            break
        default: break
        }

        fseek(file, Int(lastPost), SEEK_SET)
        return valid_pos
    }
}