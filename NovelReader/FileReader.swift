//
//  FileReader.swift
//  NovelReader
//
//  Created by kangyonggen on 3/21/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

class FilerReader {

    let BUFFER_SIZE        = 65536
    let UNKNOW_ENCODING    = "Unknow"

    // Support encodings
    let Encodings:[String] = [
        "UTF-8", "GB18030"
    ]

    func guessFileEncoding(file: UnsafeMutablePointer<FILE>) -> String
    {
        let uchar_handle      = uchardet_new()
        let cache_buffer      = UnsafeMutablePointer<Int8>.alloc(self.BUFFER_SIZE)

        while feof(file) != 0
        {
            let valid_len = fread(cache_buffer, 1, self.BUFFER_SIZE, file)
            let retval    = uchardet_handle_data(uchar_handle, cache_buffer, valid_len)

            if retval != 0
            {
                return self.UNKNOW_ENCODING
            }
        }

        uchardet_data_end(uchar_handle)

        let possible_encoding = uchardet_get_charset(uchar_handle)

        uchardet_delete(uchar_handle)

        return possible_encoding == nil ? self.UNKNOW_ENCODING : String(possible_encoding)
    }

    func isSupportEncding(encoding: String) -> Bool
    {
        return self.Encodings.contains(encoding);
    }
}