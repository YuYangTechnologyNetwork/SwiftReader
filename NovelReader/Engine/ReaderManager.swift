//
//  ReaderController.swift
//  NovelReader
//
//  Created by kang on 4/2/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

class ReaderManager: NSObject {
    enum MonitorName: String {
        case ChapterChanged
        case AsyncLoadFinish
    }

    private(set) var paperSize: CGSize = EMPTY_SIZE
    private var listeners: [MonitorName: [String: (chapter: Chapter) -> Void]] = [:]

    private(set) var book: Book!
    private var prevChapter: Chapter = Chapter.EMPTY_CHAPTER
    private var currChapter: Chapter = Chapter.EMPTY_CHAPTER
    private var nextChapter: Chapter = Chapter.EMPTY_CHAPTER

    var currPaper: Paper? {
        return currChapter.currPage!
    }

    var nextPaper: Paper? {
        if currChapter.isTail {
            return !nextChapter.isEmpty ? nextChapter.headPage : nil
        } else {
            return currChapter.nextPage
        }
    }

    var prevPaper: Paper? {
        if currChapter.isHead {
            return !prevChapter.isEmpty ? prevChapter.tailPage : nil
        } else {
            return currChapter.prevPage
        }
    }

    var currentChapter: BookMark {
        return BookMark(title: currChapter.title, range: currChapter.range)
    }

    var currBookMark: BookMark? {
        return book.bookMark
    }

    var currSelection: Chapter {
        return currChapter
    }

    var isHead: Bool {
        return currChapter.isHead && currChapter.range.loc <= 0
    }

    var isTail: Bool {
        return currChapter.isTail && currChapter.range.end >= book.size
    }

    var currentChapterPageCount: Int {
        return currChapter.pageCount
    }

    override var description: String {
        return "\nPrev: \(prevChapter)\nCurr: \(currChapter)\nNext: \(nextChapter)"
    }

    init(b: Book, size: CGSize) {
        book = b
        paperSize = size
    }

    /**
     Update bookmark
     */
    func updateBookMark() {
        if let cp = currPaper {
            book.bookMark = BookMark(
                title: cp.firstLineText?.pickFirst(50) ?? NO_TITLE,
                range: NSMakeRange(currChapter.originalOffset(), cp.realLen)
            )

            Utils.Log(book.bookMark)
            
            Db(db: Config.Db.DefaultDB, rowable: self.book).open { db in
                if !db.update(self.book, conditions: "where `\(Book.Columns.UniqueId)` = '\(self.book.uniqueId)'") {
                    Utils.Log(db.lastExecuteInfo)
                    
                    db.insert(self.book)
                }
            }
        }
    }

    /**
     Add listener that will be called on current chapter is changed

     - parameter name:     The listener name
     - parameter listener: Listener
     */
    func addListener(name: String, forMonitor m: MonitorName, listener: (chapter: Chapter) -> Void) {
        if listeners.indexForKey(m) == nil {
            listeners[m] = Dictionary < String, (chapter: Chapter) -> Void > ()
        }

        if listeners[m]!.indexForKey(name) == nil {
            listeners[m]![name] = listener
        } else {
            listeners[m]!.updateValue(listener, forKey: name)
        }
    }

    /**
     Remove added listener via name

     - parameter name: The listener name
     */
    func removeListener(name: String, forMonitor m: MonitorName) {
        if listeners.indexForKey(m) != nil {
            listeners[m]!.removeValueForKey(name)
        }
    }

    /**
     Async prepare the book and the papers

     - parameter callback: Will be call on prepare finish or error
     */
    func asyncLoading(limit: Bool = false, callback: (_: Chapter) -> Void) {
        if let bm = book.bookMark {
            currChapter = Chapter(bm: bm)
        } else {
            currChapter = Chapter(range: NSMakeRange(0, CHAPTER_SIZE))
        }

        Utils.asyncTask({ () -> (left: Bool, right: Bool) in
            // Load current chapter
            self.currChapter.load(paperSize: self.paperSize, reverse: false, book: self.book, limit: limit)
            var lazy = (true, true)

            if self.currChapter.status == Chapter.Status.Success {
                // Jump to bookmark
                if let bm = self.book.bookMark {
                    self.currChapter.locateTo(bm.range.loc)
                } else {
                    self.currChapter.setHead()
                }

                // Load prev chapter
                if self.currChapter.range.loc > 0 {
                    self.prevChapter = Chapter(range: NSMakeRange(max(self.currChapter.range.loc - 1, 0), 1))
                    //if !self.currChapter.canLazyLeft {
                        //self.prevChapter.load(paperSize: self.paperSize, reverse: true, book: self.book, limit: true)
                    //}
                } else {
                    lazy.0 = false
                }

                // Load next chapter
                if self.currChapter.range.end < self.book.size {
                    self.nextChapter = Chapter(range: NSMakeRange(self.currChapter.range.end + 1, 1))

                    //if !self.currChapter.canLazyRight {
                        //self.nextChapter.load(paperSize: self.paperSize, reverse: false, book: self.book, limit: true)
                    //}
                } else {
                    lazy.1 = false
                }
            } else {
                lazy = (false, false)
            }

            return lazy
        }) { lazy in
            Utils.Log(self)
            callback(self.currChapter)
            
            // Update book mark
            self.updateBookMark()

            if lazy.left || lazy.right {
                Utils.asyncTask({
                    if lazy.left {
                        self.prevChapter.load(paperSize: self.paperSize, reverse: true, book: self.book)
                    }

                    if lazy.right {
                        self.nextChapter.load(paperSize: self.paperSize, reverse: false, book: self.book)
                    }
                }) {
                    if let ms = self.listeners[.AsyncLoadFinish] {
                        for l in ms.values { l(chapter: self.currChapter) }
                    }
                }
            }
        }
    }

    /**
     Paging the content

     - parameter content:          chapter content
     - parameter firstListIsTitle: Is the first paper?

     - returns: array wrapped chapter's papers
     */
    func paging(content: String, firstListIsTitle: Bool = false) -> [Paper] {
        var index = 0, papers: [Paper] = []
        var lastEndWithNewLine: Bool = !firstListIsTitle

        repeat {
            let paper = Paper(size: paperSize), flit = firstListIsTitle && index == 0
            let tmpStr = content.substringFromIndex(content.startIndex.advancedBy(index))

            paper.writingLineByLine(tmpStr, firstLineIsTitle: flit, startWithNewLine: lastEndWithNewLine)

            // Skip empty paper
            if paper.realLen == 0 {
                break
            }

            lastEndWithNewLine = paper.properties.endedWithNewLine
            index = paper.realLen + index

            papers.append(paper)
        } while (index < content.length)

        return papers
    }

    func swipeToNext() {
        if !isTail {
            if currChapter.isTail {
                prevChapter.trash()
                prevChapter = currChapter.setTail()
                currChapter = nextChapter.setHead()
                nextChapter = Chapter.EMPTY_CHAPTER.setHead()

                if let ms = listeners[MonitorName.ChapterChanged] {
                    for l in ms.values {
                        l(chapter: currChapter)
                    }
                }
            } else {
                currChapter.next()
            }

            if nextChapter.isEmpty && nextChapter.status != Chapter.Status.Loading {
                self.nextChapter = Chapter(range: NSMakeRange(self.currChapter.range.end + 1, 1))
                Utils.asyncTask({ () -> Chapter.Status in
                    self.nextChapter.load(paperSize: self.paperSize, reverse: false, book: self.book)
                    return self.nextChapter.status
                }) { s in
                    if s == Chapter.Status.Success {
                        if let ms = self.listeners[MonitorName.AsyncLoadFinish] {
                            for l in ms.values {
                                l(chapter: self.nextChapter)
                            }
                        }
                    }
                }
            }

            // Auto record bookmark
            updateBookMark()
        }
    }

    func swipeToPrev() {
        if !isHead {
            if currChapter.isHead {
                nextChapter.trash()
                nextChapter = currChapter.setHead()
                currChapter = prevChapter.setTail()
                prevChapter = Chapter.EMPTY_CHAPTER.setTail()

                if let ms = listeners[MonitorName.ChapterChanged] {
                    for l in ms.values {
                        l(chapter: currChapter)
                    }
                }
            } else {
                currChapter.prev()
            }

            if prevChapter.isEmpty && prevChapter.status != Chapter.Status.Loading {
                self.prevChapter = Chapter(range: NSMakeRange(max(self.currChapter.range.loc - 1, 0), 1))
                Utils.asyncTask({ () -> Chapter.Status in
                    self.prevChapter.load(paperSize: self.paperSize, reverse: true, book: self.book)
                    return self.prevChapter.status
                }) { s in
                    if s == Chapter.Status.Success {
                        if let ms = self.listeners[MonitorName.AsyncLoadFinish] {
                            for l in ms.values {
                                l(chapter: self.prevChapter)
                            }
                        }
                    }
                }
            }

            // Auto record bookmark
            updateBookMark()
        }
    }
}
