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

    // In the set, these code can't be decode to a readable character
    private static let INVALID_SET:[String] = [
        "A1A0", "A2A0", "A2AB", "A2AC", "A2AD", "A2AE", "A2AF",
        "A2B0", "A2E3", "A2E4", "A2EF", "A2F0", "A2FE", "A2FF",
        "A895", "A989", "A98A", "A98B", "A98C", "A98D", "A98E",
        "A98F", "A990", "A991", "A992", "A993", "A994", "A995"
    ]

    // Supported encodings
    static let Encodings: [String: UInt] = [
        ENCODING_UTF8: NSUTF8StringEncoding,
        ENCODING_GB18030: CFStringConvertEncodingToNSStringEncoding(UInt32(CFStringEncodings.GB_18030_2000.rawValue))
    ]

    /*
     * Guess the special text file encoding type, use the open-source library `uchardet` by Mozilla.org
     *
     * @param file      The file pointer
     *
     * @return          The encoding name of the special file, eg: UTF-8, GB18030..
     */
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

        free(cache_buffer)

        return isSupportEncding(possible_encoding!) ? possible_encoding! : Self.UNKNOW_ENCODING
    }

    /*
     * Check the special encoding name for supportive
     *
     * @param encoding      Need check encoding name(String)
     *
     * @return Bool         If encoding is defined in Self.Encodings, true will be returned
     */
    func isSupportEncding(encoding: String) -> Bool {
        return Self.Encodings.indexForKey(encoding) != nil;
    }

    /*
     * @param file      The file pointer
     *
     * @return          The file size by bytes
     */
    func getFileSize(file: UnsafeMutablePointer<FILE>) -> Int {
        fseek(file, 0, SEEK_END)
        return ftell(file)
    }

    /*!
     * @param file      The file pointer
     *
     * @param fuzzyPos  The fuzzy file position, mybe it's the word border
     *
     * @param encoding  The iOS defined ecnoding, eg: NSUTF8StringEncoding
     *
     * @return          If got a word border success, the correct position will be returned. Failed return -1
     */
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

        free(buffer)

        return valid_pos
    }

    /* 
     * Get the UTF-8 encoding word border
     *
     * UTF-8 Foramt rules:
     * 1 byte  0xxxxxxx
     * 2 bytes 110xxxxx 10xxxxxx
     * 3 bytes 1110xxxx 10xxxxxx 10xxxxxx
     * 4 bytes 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
     * ...
     */
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

    /*
     * Get the GB18030 encoding word border
     */
    private func detectGB18030_2000Border(buffer: UnsafeMutablePointer<UInt8>, len: Int) -> Int {
        var offset = -1
        let MAX_SUCCESS_TIMES = min(len / 2, 24)

        // let echo = { (arr: UnsafeMutablePointer<UInt8>, offset: Int, len: Int) in
        //     let buf = arr + offset, l = len - offset
        //     var str = ""
        //     for i in 0 ..< l {
        //         str = str.stringByAppendingFormat("%x ", buf[i])
        //     }
        //
        //     print("\(str)=> ", separator: "", terminator: "")
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

    /*
     * Check the 2 bytes gbk code in GB18030 Encoding Table
     */
    private func atValidZone(gbkCodeTuple: (UInt8, UInt8)) -> Bool {
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
        return "^\\s{0,}第[〇一二三四五六七八九十百千零0123456789]+[章卷篇节集回]\\s{0,}.{0,30}$"
    }

    /*!
     * @param file      The file pointer
     *
     * @param callback  If open file succes, callback be called when reading categories finish
     *
     * @return          If open file failure, false will be returned
     */
    func asyncGetChapters(file: UnsafeMutablePointer<FILE>, callback: ([(String, Int)]) -> Void) -> Bool {
        if file != nil {
            let encodingStr = self.guessFileEncoding(file)

            if isSupportEncding(encodingStr) {
                let ecnoding = Self.Encodings[encodingStr]!
                let fileSize = getFileSize(file)

                dispatch_async(dispatch_queue_create("async_get_categories", nil)) {
                    var location = 0, categories: [(String, Int)] = []

                    repeat {
                        let head = self.getWordBorder(file, fuzzyPos: location, encoding: ecnoding)
                        let tail = self.getWordBorder(file, fuzzyPos: head + Self.BUFFER_SIZE, encoding: ecnoding)
                        let size = tail - head

                        if size > 0 {
                            categories += self.chaptersInRange(file, range: NSMakeRange(head, size), encoding: ecnoding)
                            location = tail
                        }
                    } while (location < fileSize)

                    dispatch_async(dispatch_get_main_queue()) {
                        callback(categories)
                    }
                }

                return true
            }
        }

        return false
    }

    /*
     * Read a snippet of file in range
     *
     * @param file      The file pointer
     *
     * @param range     The spical range, [0 ... filesize]
     *
     * @param ecnoding  The iOS defined ecnoding, eg: NSUTF8StringEncoding
     *
     * @return String   If range or encoding is illegal, nil will be returned
     */
    func readRange(file: UnsafeMutablePointer<FILE>, range: NSRange, encoding: UInt) -> String? {
        /*
         * Try read a prefect snippet in range
         */
        let snippetDetour = { (head: Int, tail: Int) -> (Bool, String?) in
            let loc = range.location - head
            let len = range.length + head + tail
            let buf = UnsafeMutablePointer<UInt8>.alloc(len)
            
            fseek(file, loc, SEEK_SET)
            
            let readed = fread(buf, 1, len, file)
            var tmpSnippet: String? = nil
            
            if readed > 0 {
                tmpSnippet = String(data: NSData(bytes: buf, length: min(readed, len)), encoding: encoding)
            }
            
            free(buf)
            
            return (readed == len, tmpSnippet)
        }
        
        var offset = 0, count = 0, dir = 0, snippet: (Bool, String?) = (true, nil)

        /*
         * If the range start and end not a word border, try to repair it.
         * The looper mybe like below:
         *   Loop 0:     range.loc ... range.loc + range.len + 1
         *   Loop 1: range.loc - 1 ... range.loc + range.len
         *   Loop 2: range.loc - 1 ... range.loc + range.len + 1
         *   Loop 3:     range.loc ... range.loc + range.len + 2
         *   ...
         */
        repeat {
            snippet = snippetDetour(dir % 2 == 0 ? offset : 0, dir > 0 ? offset : 0)
            
            if (snippet.1 == nil) {
                offset += dir == 0 ? 1 : 0
                count += 1
                dir = count % 3
            }
        } while (snippet.0 && snippet.1 == nil)
        
        return snippet.1
    }

    /*
     * Read a chapters of file in range
     *
     * @param file                  he file pointer
     *
     * @param range                 The spical range, [0 ... filesize]
     *
     * @param ecnoding              The iOS defined ecnoding, eg: NSUTF8StringEncoding
     *
     * @return (Title, location)    If range or encoding is illegal, [] will be returned
     */
    func chaptersInRange(file: UnsafeMutablePointer<FILE>, range: NSRange, encoding: UInt) -> [(String, Int)] {
        let snippet = self.readRange(file, range: range, encoding: encoding)
        var title: [(String, Int)] = []
        
        if snippet != nil {
            let lines = snippet!.characters.split(Self.getNewLineCharater(snippet!))
            var locat = range.location
            
            for line in lines {
                let str = String(line)
                if str.regexMatch(self.CHAPTER_REGEX) {
                    let chapter = str.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
                    title.append((chapter, locat))
                    print(chapter)
                } else {
                    locat += str.lengthOfBytesUsingEncoding(encoding)
                }
            }
        }
        
        return title
    }

    /*
     * Get the spical text newline charater
     * \r\n, \r:    Mybe for Windows
     *       \n:    Mybe for Linux/Unix, Mac, Windows
     */
    static func getNewLineCharater(text: String) -> Character {
        if text.characters.contains("\r\n") {
            return "\r\n"
        } else if text.characters.contains("\r") {
            return "\r"
        } else {
            return "\n"
        }
    }
}