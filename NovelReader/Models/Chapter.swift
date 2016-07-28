//
//  Chapter.swift
//  NovelReader
//
//  Created by kangyonggen on 4/20/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

class Chapter: BookMark {
    static let EMPTY_CHAPTER = Chapter()
    typealias `Self` = Chapter

    enum Status {
        case Blank
        case Loading
        case Failure
        case Success
    }

    var pageCount: Int {
        return _papers.count
    }

    var isTail: Bool {
        return _offset >= pageCount - 1
    }

    var isHead: Bool {
        return _offset <= 0
    }

    var isEmpty: Bool {
        return _papers.count == 0 /*&& status != .Loading*/
    }

    var currPage: Paper? {
        return pageCount > 0 ? _papers[_offset]: nil
    }

    var nextPage: Paper? {
        return isTail ? nil : _papers[_offset + 1]
    }

    var prevPage: Paper? {
        return isHead ? nil : _papers[_offset - 1]
    }

    var headPage: Paper? {
        return isEmpty ? nil : _papers[0]
    }

    var tailPage: Paper? {
        return isEmpty ? nil : _papers[_papers.count - 1]
    }
    
    var canLazyLeft: Bool {
        return _offset > 1
    }
    
    var canLazyRight: Bool {
        return _papers.count - _offset > 2
    }

    override var description: String {
        return isEmpty ? "Blank" : super.description
    }

    private var _offset = 0

    private var _pagedOffset = 0

    private var _papers: [Paper] = []
    private var _content: String = ""
    private var _paperSize: CGSize = EMPTY_SIZE

    private(set) var status: Status = .Blank

    private var asyncTask: dispatch_block_t? = nil

    init(bm: BookMark) {
        super.init(title: bm.title, range: bm.range)
    }

    override init(title: String = NO_TITLE, range: NSRange = EMPTY_RANGE) {
        super.init(title: title, range: range)
    }

    /**
     Async load the chapter and paging

     - parameter readerMgr: ReaderManager
     - parameter reverse:   The chapter in the range chapters head or tail
     - parameter book:      The novel book
     - parameter callback:  Will be on load finish
     */
    func asyncLoadInRange(readerMgr: ReaderManager, reverse: Bool, book: Book, callback: (_: Status) -> Void) {
        // Filter illegal range
        if !range.isLogical {
            callback(.Failure)
            return
        }

        let task = {
            // Show System StatusBar Network Indicator
            dispatch_async(dispatch_get_main_queue()) {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            }

            // Loading
            self.loadInRange(readerMgr, reverse: reverse, book: book)

            // Back to main thread
            dispatch_async(dispatch_get_main_queue()) {
                // Logging
                 Utils.Log("Loaded: \(self)")

                // Reset async task
                self.asyncTask = nil

                // Hide System StatusBar Network Indicator
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false

                // Callback
                callback(self.status)
            }
        }

        asyncTask = task
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), task)
    }

    func loadInRange(readerMgr: ReaderManager, reverse: Bool, book: Book) -> Status {
        // Filter illegal range
        if !range.isLogical {
            return .Failure
        }

        self.status  = .Loading
        let file     = fopen((book.fullFilePath), "r")
        let reader   = FileReader()

		var chapters: [BookMark]!, loc = range.loc, len = range.len + readerMgr.currSelection.range.len / 2, scale = 0
		repeat {
			chapters = reader.fetchChaptersInRange(file, range: NSMakeRange(loc, len), encoding: book.encoding)

			if chapters.count > 0 && self.range.loc > 0 && chapters.first!.title == NO_TITLE {
				chapters.removeFirst()
			}

			if chapters.count >= 2 || (reverse && loc == 0) || len == book.size - loc {
				break
            } else {
                scale += 1
            }

			if reverse {
				loc = max(range.loc - CHAPTER_SIZE * scale, 0)
				len = range.end - loc + readerMgr.currSelection.range.len / 2
			} else {
				loc = range.loc
				len = min(CHAPTER_SIZE * scale, book.size - loc)
			}
		} while true

        var ready = chapters.count > 0
        
        chapters.sortInPlace { $0.range.loc < $1.range.loc }

        // Get chapter
        if ready {
			if reverse {
				for (i, c) in chapters.enumerate() {
					if c.title == readerMgr.currSelection.title {
						range = chapters[i - 1].range
						title = chapters[i - 1].title
						break
					}
				}
			} else {
				range = chapters[0].range
				title = chapters[0].title
			}

            let content = reader.fetchRange(file, range, book.encoding).0

            if !content.isEmpty {
                _papers = readerMgr.paging(content, firstListIsTitle: self.title != NO_TITLE)
                if title == NO_TITLE {
                    title = content.componentsSeparatedByString(FileReader.getNewLineCharater(content)).first!
                }
            } else {
                ready = false
            }
        }

        self.status = ready ? .Success : .Failure

        // Close file
        fclose(file)

        return self.status
    }

    /**
     Load chapter content for range

     - parameter paperSize: Paper's bounds
     - parameter reverse:   If reverse, locate page to tail
     - parameter book:      The book
     - parameter fuzzy:     If fuzzy, need to reget content from file

     - returns: Status {Failure, Success}
     */
    func load(paperSize ps: CGSize, reverse: Bool, book: Book, fuzzy: Bool = true, limit: Bool = false) -> Status {
        if range.loc < 0 || range.end > book.size {
            self.status = .Blank
            return .Failure
        }

        let file    = fopen((book.fullFilePath), "r")
        let reader  = FileReader()
        let fetched = fuzzy ? reader.fetchChapterAtLocation(file, location: range.loc, encoding: book.encoding) : self

        if let chapter = fetched {
            range = chapter.range
            title = chapter.title

            let text = reader.fetchRange(file, range, book.encoding).0
            if !text.isEmpty {
                if reverse && limit {
                    _papers = Self.pagingTailCache(text, paperSize: ps)
                } else {
                    let pc = limit ? 2 : Int.max
                    let res = Self.paging(0, flit: true, lewl: false, content: text, paperSize: ps, limit: pc)
                    _papers      = res.paged
                    _pagedOffset = res.offset
                }

                _content     = text
                _paperSize   = ps

                if title == NO_TITLE {
                    title = text.componentsSeparatedByString(FileReader.getNewLineCharater(text)).first!
                }

                self.status = .Success

                if reverse {
                    setTail()
                } else {
                    setHead()
                }
            } else {
                self.status = .Failure
            }
        } else {
            self.status = .Failure
        }

        // Close file
        fclose(file)

        return self.status
    }

    /**
     Paging content by reverse

     - parameter content:   Full content
     - parameter paperSize: Size of pager

     - returns: Tial pages of content
     */
    class func pagingTailCache(content: String, paperSize: CGSize) -> [Paper] {
        let reverse = String(content.characters.reverse())
        let ps = Self.paging(0, flit: false, lewl: false, content: reverse, paperSize: paperSize).paged
        var tailStr = ""

        for p in ps {
            tailStr += String(p.text.characters.reverse())
        }

        return Self.paging(0, flit: false, lewl: false, content: tailStr, paperSize: paperSize).paged
    }

    /**
     Paging content bounds in paperSize

     - parameter index:     Start offset
     - parameter flit:      First line is Title?
     - parameter content:   String
     - parameter paperSize: Size of paper
     - parameter limit:     Max page count

     - returns: (paged: [Paper], offset: Int), If -1 returned, all of content had paged
     */
    class func paging(
        index: Int,
        flit: Bool,
        lewl: Bool,
        content: String,
        paperSize: CGSize,
        limit: Int = 2) -> (paged: [Paper], offset: Int)
    {
        var offset = max(0, index), papers: [Paper] = []
        var lastEndWithNewLine: Bool = lewl

        repeat {
            let paper = Paper(size: paperSize), flit = flit && offset == 0
            let tmpStr = content.substringFromIndex(content.startIndex.advancedBy(offset))

            paper.writtingLineByLine(tmpStr, firstLineIsTitle: flit, startWithNewLine: lastEndWithNewLine)

            // Skip empty paper
            if paper.realLen == 0 {
                break
            }

            lastEndWithNewLine = paper.properties.endedWithNewLine
            offset = paper.realLen + offset

            papers.append(paper)
        } while (offset < content.length && papers.count < limit)

        return (papers, papers.count < limit ? -1 : offset)
    }

    func trash() {
        if let t = asyncTask {
            if dispatch_block_testcancel(t) == 0 {
                // Logging
                Utils.Log("Canceled: \(self)")
                dispatch_block_cancel(t)
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
        }
    }

    func next() {
        _offset += 1
        _offset = min(_offset, _papers.count)

        if _offset >= _papers.count - 1 && _pagedOffset > 0 {
            let res = Self.paging(
                _pagedOffset,
                flit: true,
                lewl: false,
                content: _content,
                paperSize: _paperSize,
                limit: 2
            )

            _papers = _papers + res.paged
            _pagedOffset = res.offset
        }
    }

    func prev() {
        _offset -= 1
        _offset = max(0, _offset)
    }

    func setHead() -> Chapter {
        _offset = 0
        return self
    }

    func setTail() -> Chapter {
        _offset = _papers.count - 1
        return self
    }
    
	func locateTo(location: Int) -> Chapter? {
		var sum = 0

		for (i, p) in _papers.enumerate() {
			if range.loc + sum + p.realLen > location {
				_offset = i
				return self
			}

			sum += p.realLen
		}

		return nil
	}
    
    func originalOffset() -> Int {
        if !self._papers.isEmpty && _offset > 0 {
            var sum = 0
            for i in 0 ... (_offset - 1) {
                sum += _papers[i].realLen
            }

            return range.loc + sum
        }

        return range.loc
    }
}