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
    private var paperSize: CGSize = EMPTY_SIZE
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

    var isHead: Bool {
        return currChapter.isHead && currChapter.range.location <= 0
    }

    var isTail: Bool {
        return currChapter.isTail && currChapter.range.end >= book.size
    }

    init(b: Book, size: CGSize) {
        book = b
        paperSize = size
        encoding = FileReader.Encodings[self.book.encoding]
    }

    func asyncPrepare(callback: (_: Chapter.Status) -> Void) {
        if let bm = book.bookMark() {
            currChapter = Chapter(title: bm.title, range: bm.range)
        } else {
            currChapter = Chapter(range: NSMakeRange(0, CHAPTER_SIZE))
        }

        currChapter.asyncLoadInRange(self, reverse: false, book: book) { (s: Chapter.Status) in
            callback(s)
        }
    }

    func paging(content: String, firstListIsTitle: Bool = false) -> [Paper] {
        var index = 0, tmpStr = content, papers: [Paper] = []

        repeat {
            let paper = Paper(size: paperSize), flit = firstListIsTitle && index == 0
            tmpStr = content.substringFromIndex(content.startIndex.advancedBy(index))

            paper.writting(tmpStr, firstLineIsTitle: flit)

            if tmpStr.length > paper.text.length {
                let len = min(tmpStr.length, paper.text.length)
                paper.writting(tmpStr.substringToIndex(tmpStr.startIndex.advancedBy(len)), firstLineIsTitle: flit)
            }

            index += paper.text.length
            papers.append(paper)
        } while (index < content.length)

        return papers
    }

    func swipToNext() {
        if currChapter.isTail {
            prevChapter.trash()
            prevChapter = currChapter
            currChapter = nextChapter
            nextChapter = Chapter.EMPTY_CHAPTER
        } else {
            currChapter.next()
        }

        if nextChapter.isEmpty && !isTail {
            let loc = currChapter.range.end
            let len = min(CHAPTER_SIZE, book.size - loc)
            nextChapter = Chapter(range: NSMakeRange(loc, len))
            nextChapter.asyncLoadInRange(self, reverse: false, book: book, callback: { (s: Chapter.Status) in
                if s == Chapter.Status.Success {
                    self.nextChapter.setHead()
                }
            })
        }
    }

    func swipToPrev() {
        if currChapter.isHead {
            nextChapter.trash()
            nextChapter = currChapter
            currChapter = prevChapter
            prevChapter = Chapter.EMPTY_CHAPTER
        } else {
            currChapter.prev()
        }

        if prevChapter.isEmpty && !isHead {
            let loc = max(currChapter.range.location - CHAPTER_SIZE, 0)
            let len = currChapter.range.location - loc
            prevChapter = Chapter(range: NSMakeRange(loc, len))
            prevChapter.asyncLoadInRange(self, reverse: true, book: book, callback: { (s: Chapter.Status) in
                if s == Chapter.Status.Success {
                    self.prevChapter.setTail()
                }
            })
        }
    }
}