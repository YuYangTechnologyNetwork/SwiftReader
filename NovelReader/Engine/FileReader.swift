//
//  FileReader.swift
//  NovelReader
//
//  Created by kangyonggen on 3/21/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation
// import PromiseKit

class FileReader {
    private typealias `Self` = FileReader

    static let BUFFER_SIZE = 65536
    static let UNKNOW_ENCODING = "Unknow"
    static let ENCODING_UTF8 = "UTF-8"
    static let ENCODING_GB18030 = "GB18030"

    private var _logOn = false

    var logOff: FileReader {
        return { () -> FileReader in
            self._logOn = false
            return self
        }()
    }

    var logOn: FileReader {
        return { () -> FileReader in
            self._logOn = true
            return self
        }()
    }
    
    // In this set, these gbk-code can't be decoded to a readable character
    private static let INVALID_SET: [String] = [
        "A1A0", "A2A0", "A2AB", "A2AC", "A2AD", "A2AE", "A2AF",
        "A2B0", "A2E3", "A2E4", "A2EF", "A2F0", "A2FE", "A2FF",
        "A895", "A989", "A98A", "A98B", "A98C", "A98D", "A98E",
        "A98F", "A990", "A991", "A992", "A993", "A994", "A995"
    ]
    
    // Supported encodings
    //static let Encodings: [String: UInt] = [
        //ENCODING_UTF8: NSUTF8StringEncoding,
        //ENCODING_GB18030: CFStringConvertEncodingToNSStringEncoding(UInt32(CFStringEncodings.GB_18030_2000.rawValue))
    //]

	enum Encoding: String {
        case UNKNOW  = "Unknow"
        case UTF8    = "UTF-8"
        case GB18030 = "GB18030"
        
		func code() -> UInt {
			switch self {
			case .UTF8:
				return NSUTF8StringEncoding
			case .GB18030:
				return CFStringConvertEncodingToNSStringEncoding(UInt32(CFStringEncodings.GB_18030_2000.rawValue))
            case .UNKNOW:
                return 0
			}
		}
	}
    
    /*
     * Guess the special text file encoding type, use the open-source library `uchardet` by Mozilla.org
     *
     * @param file      The file pointer
     *
     * @return          The encoding name of the file, eg: UTF-8, GB18030.
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
    
	func guessEncoding(file: UnsafeMutablePointer<FILE>) -> Encoding {
		let uchar_handle = uchardet_new()
		let cache_buffer = UnsafeMutablePointer<Int8>.alloc(Self.BUFFER_SIZE)

		while feof(file) == 0 {
			let valid_len = fread(cache_buffer, 1, Self.BUFFER_SIZE, file)
			let retval = uchardet_handle_data(uchar_handle, cache_buffer, valid_len)

			if retval != 0 {
				return Encoding.UNKNOW
			}
		}

		uchardet_data_end(uchar_handle)
		let possible_encoding = String.fromCString(uchardet_get_charset(uchar_handle))
		uchardet_delete(uchar_handle)

		free(cache_buffer)

		return Encoding(rawValue: possible_encoding ?? "") ?? Encoding.UNKNOW
	}
    
    /*
     * Check the special encoding name for supportive
     *
     * @param encoding      Need check encoding name(String)
     *
     * @return Bool         If encoding is defined in Self.Encodings, true will be returned
     */
    func isSupportEncding(encoding: String) -> Bool {
        return Encoding(rawValue: encoding) != nil
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
    func getWordBorder(file: UnsafeMutablePointer<FILE>, fuzzyPos: Int, encoding: Encoding) -> Int {
        var valid_pos = -1
        let buffer_size = 64
        let file_size = self.getFileSize(file)
        let probable_pos = min(fuzzyPos, file_size)
        
        fseek(file, probable_pos, SEEK_SET)
        
        let buffer = UnsafeMutablePointer<UInt8>.alloc(buffer_size)
        let valid_len = fread(buffer, sizeof(UInt8), buffer_size, file)
        
        if valid_len > 0 {
            switch encoding {
            case .UTF8:
                valid_pos = self.detectUTF8Border(buffer, len: valid_len)
            case .GB18030:
                valid_pos = self.detectGB18030_2000Border(buffer, len: valid_len)
                // TODO: add new encoding type support
            default: break
            }
            
            if valid_pos == -1 && feof(file) != 0 {
                valid_pos = probable_pos + valid_len
            } else if valid_pos >= 0 {
                valid_pos = probable_pos + valid_pos
            }
        } else if valid_len == 0 && feof(file) != 0 {
            valid_pos = probable_pos
        } else {
            perror("file error, \(ferror(file)): ")
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
        let MAX_SUCCESS_TIMES = min(len / 4, 24)
        
        let check = { (arr: UnsafeMutablePointer<UInt8>, offset: Int, len: Int) -> Bool in
            let buf = arr + offset
            let str = String(data: NSData(bytes: buf, length: len), encoding: Encoding.GB18030.code())
            return str != nil && str?.length == 1
        }
        
        var index = 0, start = 0, success_times = 0, tmp_buffer = buffer
        
        while index < len {
            if success_times == 0 { tmp_buffer = buffer + index }
            
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
                index += 1
                start = 0
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
     * Check the tuple gbk-code in GB18030 Encoding Table
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
        return "^[\\u4E00-\\u9FA5]{0,4}(第[〇一二三四五六七八九十百千零0123456789]+[章卷篇节集回].{0,30})+[^。.]$"
    }
    
    /**
     Read a snippet of file in range

     - parameter file:     The file pointer
     - parameter r:        The special NSRange
     - parameter encoding: The iOS defined ecnoding, eg: NSUTF8StringEncoding

     - returns: Tuple that wrapped the snippet string and the reader NSRange
     */
    func fetchRange(file: UnsafeMutablePointer<FILE>, _ r: NSRange, _ encoding: Encoding) -> (text: String, range: NSRange) {
        var snippet: String? = nil, scope: NSRange!, head = 0, tail = 0
        let fileSize = getFileSize(file)

        /*
         * If the range start and end not a word border, try to repair it.
         * Loops mybe like below:
         *   L0:     r.loc ... r.end + 1
         *   L1: r.loc - 1 ... r.end + 1
         *   L2: r.loc - 1 ... r.end
         *   L3:     r.loc ... r.end + 2
         *   ...
         */
        repeat {
            if _logOn {
                Utils.Log("Offset: (\(head), \(tail))")
            }

            scope   = NSMakeRange(max(r.loc - head, 0), min(r.len + head + tail, fileSize - r.loc + head))
            let buf = UnsafeMutablePointer<UInt8>.alloc(scope.len)

            fseek(file, scope.loc, SEEK_SET)
            let readed = fread(buf, sizeof(UInt8), scope.len, file)
            snippet    = readed > 0 ? String(data: NSData(bytes: buf, length: readed), encoding: encoding.code()) : nil
            
            free(buf)

            if snippet == nil {
                if tail > head {
                    head += 1
                } else {
                    if head == tail && head == 0 {
                        tail = 1
                        continue
                    }

                    tail -= 1

                    if tail < 0 {
                        tail = head + 1
                        head = 0
                    }
                }
            }
        } while (snippet == nil || scope.len >= fileSize)

        return (snippet ?? "", scope)
    }

    /**
     Get the chapter range at special location

     - parameter file:     File pointer
     - parameter location: The special location
     - parameter encoding: File encoding, eg: NSUTF8StringEncoding

     - returns: nil or found chapter<BookMark>
     */
    func fetchChapterAtLocation(file: UnsafeMutablePointer<FILE>, location: Int, encoding: Encoding) -> BookMark? {
        let fileSize = getFileSize(file)
        var loc = 0, len = 0, scale = 1

        while true {
            loc = max(0, location - CHAPTER_SIZE * scale)
            len = min(CHAPTER_SIZE * (scale + 1), fileSize - loc)

            let scope = NSMakeRange(loc, len)
            var chapters = fetchChaptersInRange(file, range: scope, encoding: encoding)
            chapters.sortInPlace { $0.0.range.loc > $0.1.range.loc }

            for (i, ch) in chapters.enumerate() {
                if scope.loc > 0 && scope.end < fileSize {
                    if ch.range.loc <= location && ch.title != NO_TITLE && i != 0 {
                        return ch
                    }
                } else if scope.loc == 0 {
                    if ch.range.loc <= location && i != 0 {
                        return ch
                    }
                } else {
                    if ch.range.loc <= location && ch.title != NO_TITLE {
                        return ch
                    }
                }
            }

            if scope.loc == 0 && scope.end >= fileSize {
                break
            } else {
                scale += 1
            }
        }

        return nil
    }

    /**
     Fetch chapters of the special file

     - parameter file:     File pointer
     - parameter encoding: File encoding, eg: NSUTF8StringEncoding
     - parameter slice:    A closure to get slice chapters
     */
    func fetchChaptersOfFile(file: UnsafeMutablePointer<FILE>, encoding: Encoding, slice: (FileReader, [BookMark]) -> Void) {
        var start = 0, scale = 1
        let fileSize = getFileSize(file)

        while true {
            let loc   = max(start - 1024, 0)
            let end   = min(loc + Self.BUFFER_SIZE * 2 * scale, fileSize)
            let scope = NSMakeRange(loc, end - loc)
            let chs   = fetchChaptersInRange(file, range: scope, encoding: encoding).sort { $0.range.loc < $1.range.loc }

            var s = [BookMark]()
            for (i, ch) in chs.enumerate() {
                if (i < chs.count - 1 || scope.end >= fileSize) && ch.range.loc >= start {
                    s.append(ch)
                }
            }

            if s.isEmpty {
                scale += 1
            } else {
                scale = 1
                start = s.last!.range.end
                slice(self, s)
            }

            if scope.end >= fileSize {
                break
            }
        }
    }
    
    /*
     * Read chapters of file in range
     *
     * @param file                  The file pointer
     *
     * @param range                 The special range, [0 ... filesize]
     *
     * @param ecnoding              The iOS defined ecnoding, eg: NSUTF8StringEncoding
     *
     * @return (Title, location)    If range or encoding is illegal, [] will be returned
     */
    func fetchChaptersInRange(file: UnsafeMutablePointer<FILE>, range: NSRange, encoding: Encoding) -> [BookMark] {
        let fetchRed = fetchRange(file, range, encoding)
        let snippet  = fetchRed.0
        let scope    = fetchRed.1
        var title    = [BookMark]()
        
        if !snippet.isEmpty {
            let lines = snippet.componentsSeparatedByString(Self.getNewLineCharater(snippet))
            var loc   = scope.location
            var index = snippet.startIndex
            
            for line in lines {
                let str = String(line)
                let trimStr = str.stringByReplacingOccurrencesOfString(" ", withString: "")
                
                if trimStr.regexMatch(self.CHAPTER_REGEX) {
                    let tr = snippet.rangeOfString(
                        str,
                        options: .CaseInsensitiveSearch,
                        range: Range<String.Index>(index ..< snippet.endIndex),
                        locale: nil)
                    
                    loc       = scope.location + snippet.substringToIndex((tr?.startIndex)!).length(encoding.code())
                    index     = (tr?.endIndex)!
                    let t     = str.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
                    
                    if title.count > 0 {
                        let l = title[title.count - 1]
                        title[title.count - 1].range = NSMakeRange(l.range.loc, loc - l.range.loc)
                    }
                    
                    title.append(BookMark(title: t, range: NSMakeRange(loc, 0)))
                }
            }
            
            if title.count == 0 {
                title.append(BookMark(range: scope))
            } else {
                let l = title.last!
                title.last!.range = NSMakeRange(l.range.loc, scope.loc + snippet.length(encoding.code()) - l.range.loc)
            }
            
            if title[0].range.location > scope.location {
                title.insert(BookMark(range: NSMakeRange(scope.loc, title[0].range.loc)), atIndex: 0)
            }
        }
        
        return merge(title, encoding: encoding.code())
    }
    
    /*
     * Merge short and repeated chapter
     *
     * @param chapters        Chapters genarate by chaptersInRange
     *
     * @param encoding        The iOS defined ecnoding, eg: NSUTF8StringEncoding
     *
     * @return merged chapters
     */
    private func merge(chapters: [BookMark], encoding: NSStringEncoding) -> [BookMark] {
        if chapters.count < 2 {
            return chapters
        }
        
        var merged: [BookMark] = [], i = 0
        let count = chapters.count

        let isSimilar = { (s1: String, s2: String) -> Bool in
            var similarity = s1 == s2

            if !similarity {
                let long = s1.length >= s2.length ? s1 : s2
                let short = long == s1 ? s2 : s1
                similarity = long.containsString(short)

                if !similarity {
                    let sim = long.similarity(short)
                    similarity = sim.1 >= 0.9 || sim.0 <= 2
                }
            }

            return similarity
        }

        repeat {
            let ccp = chapters[i]

            if i < count - 1 && ccp.title.length(encoding) >= ccp.range.len / 2 {
                let ncp     = chapters[i + 1]
                let cct     = ccp.title.stringByReplacingOccurrencesOfString(" ", withString: "")
                let nct     = ncp.title.stringByReplacingOccurrencesOfString(" ", withString: "")

                if i == 0 || isSimilar(cct, nct) {
                    merged.append(BookMark(title: ccp.title,
                        range: NSMakeRange(ccp.range.loc, ccp.range.len + ncp.range.len)))
                i           += 1
                } else {
                let end     = merged.count - 1
                let endE    = merged[end]
                merged[end] = BookMark(title: endE.title,
                        range: NSMakeRange(endE.range.loc, endE.range.len + ccp.range.len))
                }
            } else {
                merged.append(ccp)
            }

            i += 1
        } while (i < count)

		#if DEBUG
            if _logOn {
                for item in merged {
                    Utils.Log(item)
                }
            }
		#endif

        return merged
    }
    
    /*
     * Get the special text newline character
     * \r\n, \r:    Mybe for Windows
     *       \n:    Mybe for Linux/Unix, Mac, Windows
     */
    static func getNewLineCharater(text: String) -> String {
        if text.characters.contains("\r\n") {
            return "\r\n"
        } else if text.characters.contains("\r") {
            return "\r"
        } else {
            return "\n"
        }
    }
}