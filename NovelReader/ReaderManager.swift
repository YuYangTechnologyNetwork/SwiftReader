//
//  ReaderController.swift
//  NovelReader
//
//  Created by kang on 4/2/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

class ReaderManager {

    private var book: Book!
    private var encoding: UInt!

    private var paperSize: CGSize = CGSizeMake(0, 0)

    private var prevChapter: (Bool, [Paper]) = (true, [])
    private var currChapter: (Bool, [Paper]) = (true, [])
    private var nextChapter: (Bool, [Paper]) = (true, [])

    var paperIndex = 0

    init(b: Book, size: CGSize) {
        book      = b
        paperSize = size
        encoding  = FileReader.Encodings[self.book.encoding]
    }
    
    func asyncPrepare(callback: (success: Bool) -> Void) {
        // Async prepare chapters
        dispatch_async(dispatch_queue_create("ready_to_open_book", nil)) {
            let file     = fopen((self.book.fullFilePath), "r")
            let reader   = FileReader()
            let chapters = reader.chaptersInRange(file, range: NSMakeRange(0, 20480), encoding: self.encoding)
            let ready    = chapters.count > 0

            if ready {
                let content      = reader.readRange(file, range: chapters[0].range, encoding: self.encoding)
                self.currChapter.1 = self.papersWithContent(content!,
                                                          firstListIsTitle: chapters[0].title != Constants.NO_TITLE)
            }

            fclose(file)
            dispatch_async(dispatch_get_main_queue()) {
                callback(success: ready)
            }
        }
    }

    private func asyncPagingChapter(chapter: BookMark, callback: (papers: [Paper]) -> Void) {
        dispatch_async(dispatch_queue_create(Constants.GLOBAL_ASYNC_QUEUE_NAME, nil)) {
            let file    = fopen((self.book.fullFilePath), "r")
            let content = FileReader().readRange(file, range: chapter.range, encoding: self.encoding)
            let papers  = self.papersWithContent(content!, firstListIsTitle: chapter.title != Constants.NO_TITLE)
            fclose(file)

            // Back to main thread
            dispatch_async(dispatch_get_main_queue()) {
                callback(papers: papers)
            }
        }
    }

    private func asyncLoadChapterInRange(range: NSRange, callback: (papers : [Paper]) -> Void) {

    }

     func papersWithContent(content: String, firstListIsTitle: Bool = false) -> [Paper] {
        var index = 0, tmpStr = content, papers: [Paper] = []
        
        repeat { 
            let paper = Paper(size: paperSize)
            let flit  = firstListIsTitle && index == 0
            tmpStr    = content.substringFromIndex(content.startIndex.advancedBy(index))

            paper.writting(tmpStr, firstLineIsTitle: flit)
            
            if tmpStr.length > paper.text.length {
                paper.writting(
                    tmpStr.substringToIndex(tmpStr.startIndex.advancedBy(paper.text.length)),
                    firstLineIsTitle: flit)
            }
            
            index += paper.text.length
            papers.append(paper)
        } while (index < content.length)
        
        return papers
    }
    
    func isHeader() -> Bool {
        return paperIndex == 0
    }
    
    func isTail() -> Bool {
        return currChapter.0 || paperIndex == currChapter.1.count - 1
    }
    
    func swipToNext() {
        paperIndex = min(paperIndex + 1, currChapter.1.count - 1)

        if paperIndex == currChapter.1.count - 1 {
            paperIndex = 0
            prevChapter = currChapter
            currChapter = nextChapter
            nextChapter = (true, [])
        }
    }
    
    func swipToPrev() {
        paperIndex = max(paperIndex - 1, 0)
    }
    
    func currPaper() -> Paper? {
        return currChapter.1[paperIndex]
    }
    
    func nextPaper() -> Paper? {
        if paperIndex == currChapter.1.count - 1 {
            return nil
        }
        
        return currChapter.1[paperIndex + 1]
    }
    
    func prevPaper() -> Paper? {
        if paperIndex == 0 {
            return nil
        }
        
        return currChapter.1[paperIndex - 1]
    }
}