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

    private static let INVALID_SET:[String] = [
        "A1A0", "A2A0", "A2AB", "A2AC", "A2AD", "A2AE", "A2AF",
        "A2B0", "A2E3", "A2E4", "A2EF", "A2F0", "A2FE", "A2FF",
        "A895", "A989", "A98A", "A98B", "A98C", "A98D", "A98E",
        "A98F", "A990", "A991", "A992", "A993", "A994", "A995"
    ]

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
        let buffer_size      = 64
        let file_size        = self.getFileSize(file)
        let probable_pos     = min(fuzzyPos, file_size)

        fseek(file, probable_pos, SEEK_SET)

        let buffer           = UnsafeMutablePointer<UInt8>.alloc(buffer_size)
        let valid_len        = fread(buffer, 1, buffer_size, file)

        if valid_len > 0 {
            switch encoding {
            case Self.Encodings[Self.ENCODING_UTF8]!:
                valid_pos = self.detectUTF8Border(buffer, len: valid_len)
            case Self.Encodings[Self.ENCODING_GB18030]!:
                valid_pos = self.detectGB18030_2000Border(buffer, len: valid_len)
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
        let MAX_SUCCESS_TIMES = min(len / 4, 24)

        // let echo = { (arr: UnsafeMutablePointer<UInt8>, offset: Int, len: Int) in
        //      let buf = arr + offset, l = len - offset
        //      var str = ""
        //      for i in 0 ..< l {
        //          str = str.stringByAppendingFormat("%x ", buf[i])
        //      }
        //
        //      print("\(str)=> ", separator: "", terminator: "")
        // }

        let check = { (arr:UnsafeMutablePointer<UInt8>, offset: Int, len: Int) -> Bool in
            let buf = arr + offset
            let str = String(
                data: NSData(bytes: buf, length: len),
                encoding: FileReader.Encodings[Self.ENCODING_GB18030]!
            )

            // echo(buf, 0, len)
            // print(str)

            return str != nil && str?.length == 1
        }


        var index = 0, start = 0, success_times = 0, tmp_buffer = buffer

        while index < len {
            if success_times == 0 {
                // print("------------------ \(index)")
                // echo(buffer, index, len - index)
                tmp_buffer = buffer + index
            }

            if check(tmp_buffer, start, 1) && atValidZone((tmp_buffer[start], 0)) {
                start += 1
                success_times += 1
            } else if check(tmp_buffer, start, 2) && atValidZone((tmp_buffer[start], tmp_buffer[start + 1])) {
                start += 2
                success_times += 1
            } else if check(tmp_buffer, start, 4) {
                start += 4
                success_times += 1
            } else {
                index         += 1
                start         = 0
                success_times = 0
            }

            if success_times >= MAX_SUCCESS_TIMES {
                offset = index
                break
            }
        }

        return offset
    }

    private func atValidZone(gbkCodeTuple: (UInt8, UInt8)) -> Bool {

        // print(String.init(format: "(%x, %x)", gbkCodeTuple.0, gbkCodeTuple.1))

        switch gbkCodeTuple {
        case (0x00 ... 0x7f as ClosedInterval, 0x00 ... 0xff as ClosedInterval),
             (0xa1 ... 0xa3 as ClosedInterval, 0xa1 ... 0xff as ClosedInterval),
             (0xa8 ... 0xa9 as ClosedInterval, 0x40 ... 0x96 as ClosedInterval),
             (0xb0 ... 0xf7 as ClosedInterval, 0xa1 ... 0xfe as ClosedInterval),
             (0x81 ... 0xfd as ClosedInterval, 0x40 ... 0xa0 as ClosedInterval),
             (0xfe, 0x40 ... 0x4f as ClosedInterval):
            return !Self.INVALID_SET.contains("\(gbkCodeTuple.0)\(gbkCodeTuple.1)".uppercaseString)
        default:
            return false
        }
    }
}

extension FileReader {
    private var CHAPTER_REGEX: String {
        return "^\\s{0,}第[〇一二三四五六七八九十百千零0123456789]+[章卷篇节集回].*(\r|\n)"
    }

    func getCategories(file: UnsafeMutablePointer<FILE>, range: NSRange, encoding: UInt) -> [(String, Int)] {
        let buffer = UnsafeMutablePointer<UInt8>.alloc(range.length)

        fseek(file, range.location, SEEK_SET)
        fread(buffer, 1, range.length, file)

        let snippet = String(data: NSData(bytes: buffer, length: range.length), encoding: encoding)
        var title: [(String, Int)] = []

        if snippet != nil {
            print(snippet)
            let lines = snippet!.characters.split("\n")
            var offset = 0

            for line in lines {
                let str = String(line)
                if str.regexMatch(self.CHAPTER_REGEX) {
                    title.append((str, offset))
                } else {
                    offset += str.lengthOfBytesUsingEncoding(encoding)
                }
            }
        }

        return title
    }
}