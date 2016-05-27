//
//  ReaderController.swift
//  NovelReader
//
//  Created by kang on 4/2/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

class ReaderManager: NSObject {
    enum MonitorName:String {
        case ChapterChanged
        case AsyncLoadFinish
    }
    
    private class Buffer {
		var relativeChapter: Chapter!
		var data: Chapter? = nil

		init(relative: Chapter) {
			relativeChapter = relative
		}
    }

    private var book: Book!
    private var encoding: UInt!
    private var paperSize: CGSize = EMPTY_SIZE
    private var prevChapter: Chapter = Chapter.EMPTY_CHAPTER
    
    private var currChapter: Chapter = Chapter.EMPTY_CHAPTER
    
    private var nextChapter: Chapter = Chapter.EMPTY_CHAPTER
    private var listeners: [MonitorName: [String:(chpater: Chapter) -> Void]] = [:]

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
    
    var currentChapterPageCount:Int {
        return currChapter.pageCount
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
     Upadte bookmark
     */
    func updateBookMark() {
        if let cp = currPaper {
            book.bookMark = BookMark(
                title: cp.firstLineText?.pickFirst(10) ?? NO_TITLE,
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
    func addListener(name:String, forMonitor m:MonitorName, listener: (chpater: Chapter) -> Void) {
		if listeners.indexForKey(m) == nil {
			listeners[m] = Dictionary< String, (chpater: Chapter) -> Void > ()
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

        Utils.asyncTask({
            // Load current chapter
            self.currChapter.load(self, reverse: false, book: self.book)
            
            if self.currChapter.status == Chapter.Status.Success {
                // Jump to bookmark
                if let bm = self.book.bookMark {
                    self.currChapter.locateTo(bm.range.loc)
                } else {
                    self.currChapter.setHead()
                }
                
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
        }) {
            Utils.Log(self)
            callback(self.currChapter)
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
                
				if let ms = listeners[MonitorName.ChapterChanged] {
					for l in ms.values {
						l(chpater: currChapter)
					}
				}
            } else {
                currChapter.next()
            }

            if nextChapter.isEmpty && nextChapter.status != Chapter.Status.Loading {
                let loc = currChapter.range.end
                let len = min(CHAPTER_SIZE, book.size - loc)
                nextChapter = Chapter(range: NSMakeRange(loc, len)).setHead()
                nextChapter.asyncLoadInRange(self, reverse: false, book: book, callback: { (s: Chapter.Status) in
                    if s == Chapter.Status.Success {
                        if let ms = self.listeners[MonitorName.AsyncLoadFinish] {
                            for l in ms.values {
                                l(chpater: self.nextChapter)
                            }
                        }
                    }
                })
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
                let loc = max(currChapter.range.loc - CHAPTER_SIZE, 0)
                let len = min(currChapter.range.loc - loc, CHAPTER_SIZE - 1)
                prevChapter = Chapter(range: NSMakeRange(loc, len)).setTail()
                prevChapter.asyncLoadInRange(self, reverse: true, book: book, callback: { (s: Chapter.Status) in
                    if s == Chapter.Status.Success {
                        if let ms = self.listeners[MonitorName.AsyncLoadFinish] {
                            for l in ms.values {
                                l(chpater: self.prevChapter)
                            }
                        }
                    }
                })
            }

            // Auto record bookmark
            updateBookMark()
        }
    }
}