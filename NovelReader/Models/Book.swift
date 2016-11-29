//
//  Book.swift
//  NovelReader
//
//  Created by kangyonggen on 3/29/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

class Book: NSObject, Rowable, NSCoding {
    final class Columns {
        static let Name             = "Name"
        static let Path             = "Path"
        static let Encoding         = "Encoding"
        static let Size             = "Size"
        static let LastOpenTime     = "LastOpenTime"
        static let BookMarkTitle    = "BookMarkTitle"
        static let BookMarkPosition = "BookMarkPosition"
        static let UniqueId         = "UniqueId"
    }
    
    var currentPrecent: CGFloat {
        return size <= 0 ? 0 : (CGFloat)(bookMark?.range.loc ?? 0) / (CGFloat)(size)
    }
    
    /* File name, not include suffix */
    var name: String = ""

    /* TXT file encoding */
    var encoding: FileReader.Encoding = FileReader.Encoding.UNKNOWN

    /* File suffix */
    var type: String = ""

    /* Last opened time, for seconds */
    var lastOpenTime: Int = 0

    /* Full file path */
    var fullFilePath: String = ""

    /* File size by bytes */
    var size: Int = 0
    
    var bookMark: BookMark? = nil //BookMark(range: NSMakeRange(764027, CHAPTER_SIZE))

    /*!
     * @param fullFilePath  Full file path
     *
     * @throw If can't open file at fullFilePath, throw an Error.FileNotExist(fullFilePath)
     */
    init?(fullFilePath: String, getInfo: Bool = false) {
        super.init()
        
        self.fullFilePath = fullFilePath
        
        if getInfo {
            if fetchBookInfo() == nil {
                return nil
            }
        }
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.fullFilePath, forKey: Columns.Path)
        aCoder.encodeInteger(self.lastOpenTime, forKey: Columns.LastOpenTime)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init()
        
        self.fullFilePath = aDecoder.decodeObjectForKey(Columns.Path) as? String ?? ""
        self.lastOpenTime = aDecoder.decodeIntegerForKey(Columns.LastOpenTime)
        
        if self.fetchBookInfo() == nil {
            return nil
        }
    }
    
    init(otherBook: Book) {
        super.init()
        
        self.fullFilePath = otherBook.fullFilePath
        self.name         = otherBook.name
        self.encoding     = otherBook.encoding
        self.type         = otherBook.type
        self.lastOpenTime = otherBook.lastOpenTime
        self.size         = otherBook.size
        self.bookMark     = otherBook.bookMark
    }
    
    func fetchBookInfo() -> Book? {
        let file = fopen(self.fullFilePath, "r")
        
        if file == nil {
            return nil
        } else {
            let split = fullFilePath.characters.split("/")
            
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
        self.encoding = reader.guessEncoding(file)
        
        if self.encoding != .UNKNOWN {
            self.size = reader.getFileSize(file)
        }
        
        fclose(file)
        
        return self
    }

    override var description: String {
        return "\nName: \(self.name)\nSize: \(self.size)\n" +
            "Type: \(self.type)\nPath:\(self.fullFilePath)\nEncoding: \(self.encoding)"
    }

    var uniqueId: String {
        return description.md5()
    }
    
    var rowId: Int = 0

    var fields: [Db.Field] {
        return[.TEXT(name: Columns.Name, value: name),
               .TEXT(name: Columns.Path, value: fullFilePath),
               .TEXT(name: Columns.Encoding, value: encoding.rawValue),
               .INTEGER(name: Columns.Size, value: size),
               .INTEGER(name: Columns.LastOpenTime, value: lastOpenTime),
               .TEXT(name: Columns.BookMarkTitle, value: bookMark?.title ?? ""),
               .INTEGER(name: Columns.BookMarkPosition, value: bookMark?.range.loc ?? 0),
               .TEXT(name: Columns.UniqueId, value: uniqueId)]
    }
    
    var table: String {
        return Config.Db.Table_Bookshelf
    }
    
    func parse(row: [AnyObject]) -> Rowable? {
        Utils.Log(row)
        
        let newBook = Book(fullFilePath: row[1] as! String, getInfo: true)
        
        if newBook != nil {
            newBook!.bookMark = BookMark(title: row[5] as! String, range: NSMakeRange(row[6] as! Int, CHAPTER_SIZE))
            newBook!.lastOpenTime = row[4] as! Int
        }
        
        return newBook
    }
    
    func isFetchedCatalog() -> Bool {
        let user = NSUserDefaults.standardUserDefaults()
        let cflt = user.integerForKey(self.fullFilePath.md5() + "CatalogFetch")
        return cflt > 0
    }
    
    func setCatalogFetched(toClear: Bool = false) {
        let user = NSUserDefaults.standardUserDefaults()
        
        if !toClear {
            let timestamp = (Int)(NSDate().timeIntervalSince1970 * 1000)
            user.setInteger(timestamp, forKey: self.fullFilePath.md5() + "CatalogFetch")
        } else {
            user.setInteger(0, forKey: self.fullFilePath.md5() + "CatalogFetch")
        }
    }
}
