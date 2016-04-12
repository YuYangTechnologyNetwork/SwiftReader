//
//  ReaderController.swift
//  NovelReader
//
//  Created by kang on 4/2/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

class ReaderManager {
    
    /*Singleton*/
    static let Ins = ReaderManager()
    private init() { }
    
    private var book: Book?
    private var paperSize: CGSize = CGSizeMake(0, 0)
    private var prevChapter: [Paper] = []
    private var currChapter: [Paper] = []
    private var nextChapter: [Paper] = []
    var indexAtCurrChapter = 0
    
    func initalize(book: Book, paperSize: CGSize) {
        self.book = book
        self.paperSize = paperSize
    }

    func asyncPrepare(callback: (success: Bool) -> Void) {
        // Async prepare chapters
        dispatch_async(dispatch_queue_create("ready_to_open_book", nil)) {
            let file     = fopen((self.book?.fullFilePath)!, "r")
            let encoding = FileReader.Encodings[(self.book?.encoding)!]
            let reader   = FileReader()
            let chapters = reader.chaptersInRange(file, range: NSMakeRange(0, 20480), encoding: encoding!)
            let ready    = chapters.count > 0

            if ready {
                let content      = reader.readRange(file, range: chapters[0].range, encoding: encoding!)
                self.currChapter = self.papersWithContent(content!)
            }

            dispatch_async(dispatch_get_main_queue()) {
                callback(success: ready)
            }
        }
    }

    func asyncLoad(callback: (success: Bool) -> Void) -> Bool {
        // Async load book content
        dispatch_async(dispatch_queue_create("ready_to_open_book", nil)) {
            let file = fopen((self.book?.fullFilePath)!, "r")
            let encoding = FileReader.Encodings[(self.book?.encoding)!]
            let reader = FileReader()
            
            let chapters = reader.chaptersInRange(file, range: NSMakeRange(0, 20480), encoding: encoding!)
            let content = reader.readRange(file, range: chapters[1].range, encoding: encoding!)

            print(chapters)
            
            self.currChapter = self.papersWithContent(content!)
            
            dispatch_async(dispatch_get_main_queue()) {
                callback(success: true)
            }
        }
        
        return true
    }
    
    private func papersWithContent(content: String) -> [Paper] {
        var index = 0, tmpStr = content, papers: [Paper] = []
        
        repeat {
            let paper = Paper(size: paperSize)
            tmpStr = content.substringFromIndex(content.startIndex.advancedBy(index))
            paper.werittingText(tmpStr, firstLineIsTitle: index == 0)
            
            if tmpStr.length > paper.text.length {
                paper.werittingText(tmpStr.substringToIndex(tmpStr.startIndex.advancedBy(paper.text.length)), firstLineIsTitle: index == 0)
            }
            
            index += paper.text.length
            papers.append(paper)
        } while (index < content.length)
        
        return papers
    }
    
    func isHeader() -> Bool {
        return indexAtCurrChapter == 0
    }
    
    func isTail() -> Bool {
        return indexAtCurrChapter == currChapter.count - 1
    }
    
    func swipToNext() {
        indexAtCurrChapter = min(indexAtCurrChapter + 1, currChapter.count - 1)
    }
    
    func swipToPrev() {
        indexAtCurrChapter = max(indexAtCurrChapter - 1, 0)
    }
    
    func currPaper() -> Paper? {
        return currChapter[indexAtCurrChapter]
    }
    
    func nextPaper() -> Paper? {
        if indexAtCurrChapter == currChapter.count - 1 {
            return nil
        }
        
        return currChapter[indexAtCurrChapter + 1]
    }
    
    func prevPaper() -> Paper? {
        if indexAtCurrChapter == 0 {
            return nil
        }
        
        return currChapter[indexAtCurrChapter - 1]
    }
}