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

    private var paperSize: CGSize = EMPTY_SIZE
    private var listeners: [MonitorName: [String: (chpater: Chapter) -> Void]] = [:]

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
     Upadte bookmark
     */
    func updateBookMark() {
        if let cp = currPaper {
            book.bookMark = BookMark(
                title: cp.firstLineText?.pickFirst(5) ?? NO_TITLE,
                range: NSMakeRange(currChapter.originalOffset(), cp.realLen)
            )

            Utils.Log(book.bookMark)
        }
    }

    /**
     Add listener that will be called on current chpater is changed

     - parameter name:     The listener name
     - parameter listener: Listener
     */
    func addListener(name: String, forMonitor m: MonitorName, listener: (chpater: Chapter) -> Void) {
        if listeners.indexForKey(m) == nil {
            listeners[m] = Dictionary < String, (chpater: Chapter) -> Void > ()
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
     Aysnc prepare the book and the papers

     - parameter callback: Will be call on prepare finish or error
     */
    func asyncLoading(callback: (_: Chapter) -> Void) {
        if let bm = book.bookMark {
            currChapter = Chapter(bm: bm)
        } else {
            currChapter = Chapter(range: NSMakeRange(0, CHAPTER_SIZE))
        }

        Utils.asyncTask({ () -> (left: Bool, right: Bool) in
            // Load current chapter
            self.currChapter.load(self, reverse: false, book: self.book)
            var lazy = (false, false)

            if self.currChapter.status == Chapter.Status.Success {
                // Jump to bookmark
                if let bm = self.book.bookMark {
                    self.currChapter.locateTo(bm.range.loc)
                } else {
                    self.currChapter.setHead()
                }

                // Load prev chapter
                self.prevChapter = Chapter(range: NSMakeRange(max(self.currChapter.range.loc - 1, 0), 1))
                if !self.currChapter.canLazyLeft {
                    self.prevChapter.load(self, reverse: true, book: self.book)
                    lazy.0 = true
                }

                // Load next chapter
                self.nextChapter = Chapter(range: NSMakeRange(self.currChapter.range.end + 1, 1))

                if !self.currChapter.canLazyRight {
                    self.nextChapter.load(self, reverse: false, book: self.book)
                    lazy.1 = true
                }
            }

            return lazy
        }) { lazy in
            Utils.Log(self)
            callback(self.currChapter)

            if lazy.left || lazy.right {
                Utils.asyncTask({
                    if lazy.left { self.prevChapter.load(self, reverse: true, book: self.book) }
                    if lazy.right { self.nextChapter.load(self, reverse: false, book: self.book) }
                }) {
                    if let ms = self.listeners[.AsyncLoadFinish] {
                        for l in ms.values { l(chpater: self.prevChapter) }
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
        var index = 0, tmpStr = content, papers: [Paper] = []
        var lastEndWithNewLine: Bool = !firstListIsTitle

        repeat {
            let paper = Paper(size: paperSize), flit = firstListIsTitle && index == 0
            tmpStr = content.substringFromIndex(content.startIndex.advancedBy(index))

            paper.writtingLineByLine(tmpStr, firstLineIsTitle: flit, startWithNewLine: lastEndWithNewLine)

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

    func swipToNext() {
        if !isTail {
            if currChapter.isTail {
                prevChapter.trash()
                prevChapter = currChapter.setTail()
                currChapter = nextChapter.setHead()
                nextChapter = Chapter.EMPTY_CHAPTER.setHead()

                if let ms = listeners[MonitorName.ChapterChanged] {
                    for l in ms.values {
                        l(chpater: currChapter)
                    }
                }
            } else {
                currChapter.next()
            }

            if nextChapter.isEmpty && nextChapter.status != Chapter.Status.Loading {
                self.nextChapter = Chapter(range: NSMakeRange(self.currChapter.range.end + 1, 1))
                Utils.asyncTask({ () -> Chapter.Status in
                    self.nextChapter.load(self, reverse: false, book: self.book)
                    return self.nextChapter.status
                }) { s in
                    if s == Chapter.Status.Success {
                        if let ms = self.listeners[MonitorName.AsyncLoadFinish] {
                            for l in ms.values {
                                l(chpater: self.nextChapter)
                            }
                        }
                    }
                }

                //let loc = currChapter.range.end
                //let len = min(CHAPTER_SIZE, book.size - loc)
                //nextChapter = Chapter(range: NSMakeRange(loc, len)).setHead()
                //nextChapter.asyncLoadInRange(self, reverse: false, book: book, callback: { (s: Chapter.Status) in
                    //if s == Chapter.Status.Success {
                        //if let ms = self.listeners[MonitorName.AsyncLoadFinish] {
                            //for l in ms.values {
                                //l(chpater: self.nextChapter)
                            //}
                        //}
                    //}
                //})
            }

            // Auto record bookmark
            updateBookMark()
        }
    }

    func swipToPrev() {
        if !isHead {
            if currChapter.isHead {
                nextChapter.trash()
                nextChapter = currChapter.setHead()
                currChapter = prevChapter.setTail()
                prevChapter = Chapter.EMPTY_CHAPTER.setTail()

                if let ms = listeners[MonitorName.ChapterChanged] {
                    for l in ms.values {
                        l(chpater: currChapter)
                    }
                }
            } else {
                currChapter.prev()
            }

            if prevChapter.isEmpty && prevChapter.status != Chapter.Status.Loading {
                self.prevChapter = Chapter(range: NSMakeRange(max(self.currChapter.range.loc - 1, 0), 1))
                Utils.asyncTask({ () -> Chapter.Status in
                    self.prevChapter.load(self, reverse: true, book: self.book)
                    return self.prevChapter.status
                }) { s in
                    if s == Chapter.Status.Success {
                        if let ms = self.listeners[MonitorName.AsyncLoadFinish] {
                            for l in ms.values {
                                l(chpater: self.prevChapter)
                            }
                        }
                    }
                }

                //let loc = max(currChapter.range.loc - CHAPTER_SIZE, 0)
                //let len = min(currChapter.range.loc - loc, CHAPTER_SIZE - 1)
                //prevChapter = Chapter(range: NSMakeRange(loc, len)).setTail()
                //prevChapter.asyncLoadInRange(self, reverse: true, book: book, callback: { (s: Chapter.Status) in
                    //if s == Chapter.Status.Success {
                        //if let ms = self.listeners[MonitorName.AsyncLoadFinish] {
                            //for l in ms.values {
                                //l(chpater: self.prevChapter)
                            //}
                        //}
                    //}
                //})
            }

            // Auto record bookmark
            updateBookMark()
        }
    }
}