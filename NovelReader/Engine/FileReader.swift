//
//  FileReader.swift
//  NovelReader
//
//  Created by kangyonggen on 3/21/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

class FileReader {
    private typealias `Self`    = FileReader
    static let BUFFER_SIZE      = 65536
    static let UNKNOW_ENCODING  = "Unknow"
    static let ENCODING_UTF8    = "UTF-8"
    static let ENCODING_GB18030 = "GB18030"

    // Support encodings
    static let Encodings: [String: UInt] = [
        ENCODING_UTF8: NSUTF8StringEncoding,
        ENCODING_GB18030: CFStringConvertEncodingToNSStringEncoding(UInt32(CFStringEncodings.GB_18030_2000.rawValue))
    ]

    func guessFileEncoding(file: UnsafeMutablePointer<FILE>) -> String {
        let uchar_handle = uchardet_new()
        let cache_buffer = UnsafeMutablePointer<Int8>.alloc(Self.BUFFER_SIZE)

        while feof(file) == 0 {
            let valid_len = fread(cache_buffer, 1, Self.BUFFER_SIZE, file)
            let retval = uchardet_handle_data(uchar_handle, cache_buffer, valid_len)

            if retval != 0 {
                return Self.UNKNOW_ENCODING
            }
        }

        uchardet_data_end(uchar_handle)
        let possible_encoding = String.fromCString(uchardet_get_charset(uchar_handle))
        uchardet_delete(uchar_handle)
        return isSupportEncding(possible_encoding!) ? possible_encoding! : Self.UNKNOW_ENCODING
    }

    func isSupportEncding(encoding: String) -> Bool {
        return Self.Encodings.indexForKey(encoding) != nil;
    }

    func getFileSize(file: UnsafeMutablePointer<FILE>) -> Int {
        fseek(file, 0, SEEK_END)
        return ftell(file)
    }

    func getWordBorder(file: UnsafeMutablePointer<FILE>, fuzzyPos: Int, encoding: UInt) -> Int {
        var valid_pos        = -1
        let buffer_size      = 8
        let file_size        = self.getFileSize(file)
        let probable_pos     = min(fuzzyPos, file_size)

        fseek(file, probable_pos, SEEK_SET)

        let buffer           = UnsafeMutablePointer<UInt8>.alloc(buffer_size)
        let valid_len        = fread(buffer, 1, buffer_size, file)

        if valid_len > 0 {
            switch encoding {
            case Self.Encodings[Self.ENCODING_UTF8]!:
                valid_pos = self.detectUTF8Border(buffer, len: buffer_size)
            case Self.Encodings[Self.ENCODING_GB18030]!:
                valid_pos = self.detectGB18030_2000Border(buffer, len: buffer_size)
            default: break
            }

            if valid_pos == -1 && feof(file) != 0 {
                valid_pos = probable_pos + valid_len
            } else if valid_pos >= 0 {
                valid_pos = probable_pos + valid_pos
            }
        } else if valid_len == 0 && feof(file) != 0 {
            valid_pos = probable_pos
        }

        return valid_pos
    }

    private func detectUTF8Border(buffer: UnsafeMutablePointer<UInt8>, len: Int) -> Int {
        var offset = -1

        for i in 0 ..< len {
            if buffer[i] & 0x80 == 0 || buffer[i] & 0xc0 == 0xc0 {
                offset = i
                break
            }
        }

        return offset
    }

    private func detectGB18030_2000Border(buffer: UnsafeMutablePointer<UInt8>, len: Int) -> Int {
        var offset = -1

        for i in 0 ..< len {
            let b = buffer[i]
            let nb = buffer[i + 1]
            print(String.init(format: "%x %x", b, nb))

            if 0x81 <= b && b <= 0xFE {
                if (0x30 <= nb && nb <= 0x39) || (0x40 <= nb && nb <= 0xFE && nb != 0x7F) {
                    offset = i
                    break
                }
            } else if (0x00 <= b && b <= 0x7F) && (0x00 <= nb && nb <= 0x7f) {
                offset = i
                break
            }
        }

        return offset
    }
}
