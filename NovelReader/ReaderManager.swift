//
//  ReaderController.swift
//  NovelReader
//
//  Created by kang on 4/2/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

class ReaderManager: NSObject {
    private var book: Book!
    private var encoding: UInt!
    private var paperSize: CGSize = EMPTY_SIZE
    private var prevChapter: Chapter = Chapter.EMPTY_CHAPTER
    private var currChapter: Chapter = Chapter.EMPTY_CHAPTER
    private var nextChapter: Chapter = Chapter.EMPTY_CHAPTER
    private var listeners: [String: (chpater: Chapter) -> Void] = [:]

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

    var currBookMark: BookMark {
        return currChapter
    }

    var isHead: Bool {
        return currChapter.isHead && currChapter.range.loc <= 0
    }

    var isTail: Bool {
        return currChapter.isTail && currChapter.range.end >= book.size
    }

    override var description: String {
        return "\nPrev: \(prevChapter)\nCurr: \(currChapter)\nNext: \(nextChapter)"
    }

    init(b: Book, size: CGSize) {
        book = b
        paperSize = size
        encoding = FileReader.Encodings[self.book.encoding]
    }

    /**
     Add listener that will be called on current chpater is changed

     - parameter name:     The listener name
     - parameter listener: Listener
     */
    func addListener(name: String, listener: (chpater: Chapter) -> Void) {
        if listeners.indexForKey(name) == nil {
            listeners[name] = listener
        }
    }

    /**
     Remove added listener via name

     - parameter name: The listener name
     */
    func removeListener(name: String) {
        if listeners.indexForKey(name) != nil {
            listeners.removeValueForKey(name)
        }
    }

    /**
     Aysnc prepare the book and the papers

     - parameter callback: Will be call on prepare finish or error
     */
    func asyncPrepare(callback: (_: Chapter) -> Void) {
        if let bm = book.bookMark() {
            currChapter = Chapter(bm: bm)
        } else {
            currChapter = Chapter(range: NSMakeRange(0, CHAPTER_SIZE))
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            // Load current chapter
            self.currChapter.loadInRange(self, reverse: false, book: self.book)

            if self.currChapter.status == Chapter.Status.Success {
                // Load prev chapter
                var loc = max(self.currChapter.range.loc - CHAPTER_SIZE, 0)
                var len = min(self.currChapter.range.loc - loc, CHAPTER_SIZE - 1)
                var ran = NSMakeRange(loc, len)

                if ran.isLogical {
                    self.prevChapter = Chapter(range: ran)
                    self.prevChapter.setTail()
                    self.prevChapter.loadInRange(self, reverse: true, book: self.book)
                }

                // Load next chapter
                loc = self.currChapter.range.end
                len = min(CHAPTER_SIZE, self.book.size - loc)
                ran = NSMakeRange(loc, len)

                if ran.isLogical {
                    self.nextChapter = Chapter(range: ran)
                    self.nextChapter.setHead()
                    self.nextChapter.loadInRange(self, reverse: false, book: self.book)
                }
            }

            // Back to main thread
            dispatch_async(dispatch_get_main_queue()) {
                Utils.Log(self)
                callback(self.currChapter)
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

            lastEndWithNewLine = paper.endWithNewLine
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
                
                for l in self.listeners {
                    l.1(chpater: self.currChapter)
                }
            } else {
                currChapter.next()
            }

            if nextChapter.isEmpty && nextChapter.status != Chapter.Status.Loading {
                Utils.Log("Loading next...")
                let loc = currChapter.range.end
                let len = min(CHAPTER_SIZE, book.size - loc)
                nextChapter = Chapter(range: NSMakeRange(loc, len)).setHead()
                nextChapter.asyncLoadInRange(self, reverse: false, book: book, callback: { (s: Chapter.Status) in
                    if s == Chapter.Status.Success {
                        Utils.Log(self)
                    }
                })
            }
        }
    }

    func swipToPrev() {
        if !isHead {
            if currChapter.isHead {
                nextChapter.trash()
                nextChapter = currChapter.setHead()
                currChapter = prevChapter.setTail()
                prevChapter = Chapter.EMPTY_CHAPTER.setTail()
                
                for l in self.listeners {
                    l.1(chpater: self.currChapter)
                }
            } else {
                currChapter.prev()
            }

            if prevChapter.isEmpty && prevChapter.status != Chapter.Status.Loading {
                Utils.Log("Loading prev...")
                let loc = max(currChapter.range.loc - CHAPTER_SIZE, 0)
                let len = min(currChapter.range.loc - loc, CHAPTER_SIZE - 1)
                prevChapter = Chapter(range: NSMakeRange(loc, len)).setTail()
                prevChapter.asyncLoadInRange(self, reverse: true, book: book, callback: { (s: Chapter.Status) in
                    if s == Chapter.Status.Success {
                        Utils.Log(self)
                    }
                })
            }
        }
    }
}