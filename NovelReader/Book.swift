//
//  Book.swift
//  NovelReader
//
//  Created by kangyonggen on 3/29/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

class Book: NSObject {
    /* File name, not include subfix */
    var name: String = ""

    /* TXT file encoding */
    var encoding: String = FileReader.UNKNOW_ENCODING

    /* File subfix */
    var type: String = ""

    /* Last opened time, for seconds */
    var lastOpenTime: UInt = 0

    /* Full file path */
    var fullFilePath: String = ""

    /* File size by bytes */
    var size: Int = 0

    /*!
     * @param fullFilePath  Full file path
     *
     * @throw If can't open file by fullFilePath, throw an Error.FileNotExist(fullFilePath)
     */
    init(fullFilePath: String) throws {
        let file = fopen(fullFilePath, "r")

        if file == nil {
            throw Error.FileNotExist(fullFilePath)
        } else {
            let split = fullFilePath.characters.split("/")
            self.fullFilePath = fullFilePath

            if split.count > 1 {
                self.name = String(split[split.count - 1])
                let explode = self.name.characters.split(".")

                if explode.count > 1 {
                    self.type = String(explode[explode.count - 1])
                    self.name = self.name.substringToIndex(self.name.endIndex.advancedBy(-self.type.length - 1))
                }
            }
        }

        let reader = FileReader()
        self.encoding = reader.guessFileEncoding(file)

        if reader.isSupportEncding(self.encoding) {
            self.size = reader.getFileSize(file)
        }

        fclose(file)
    }

    override var description: String {
        return "Name: \(self.name)\nSize: \(self.size)\n" +
            "Type: \(self.type)\nPath:\(self.fullFilePath)\nEncoding: \(self.encoding)"
    }

    override var hashValue: Int {
        return description.hashValue
    }
}