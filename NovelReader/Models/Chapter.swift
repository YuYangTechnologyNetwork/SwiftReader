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
        return _papers.count == 0 && status != .Loading
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

    override var description: String {
        return isEmpty ? "Blank" : super.description
    }

    private var _offset = 0 {
        didSet {
            offset = _offset
        }
    }

    private var _papers: [Paper] = []

    private(set) var status: Status = .Blank

    private var asyncTask: dispatch_block_t? = nil

    init(bm: BookMark) {
        super.init(title: bm.title, range: bm.range)
        _offset = bm.offset
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
        if range.end <= range.location {
            callback(.Failure)
            return
        }

        let task = {
            // Show System StatusBar Network Indicator
            dispatch_async(dispatch_get_main_queue()) {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            }

            self.status = .Loading

            // Open file
            let file = fopen((book.fullFilePath), "r")
            let encoding = FileReader.Encodings[book.encoding]
            let reader = FileReader()
            var chapters = reader.chaptersInRange(file, range: self.range, encoding: encoding!)

            if chapters.count > 0 && self.range.loc > 0 && chapters.first!.title == NO_TITLE {
                chapters.removeFirst()
            }

            let ready = chapters.count > 0

            // Get chapter
            if ready {
                if reverse {
                    self.range = (chapters.last?.range)!
                    self.title = (chapters.last?.title)!
                } else {
                    self.range = (chapters.first?.range)!
                    self.title = (chapters.first?.title)!
                }

                let content = reader.readRange(file, range: self.range, encoding: encoding!)
                self._papers = readerMgr.paging(content!, firstListIsTitle: self.title != NO_TITLE)
            } else {
                Utils.Log(chapters)
            }

            self.status = ready ? .Success : .Failure

            // Close file
            fclose(file)

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
    }

    func prev() {
        _offset -= 1
        _offset = max(0, _offset)
    }

    func setHead() {
        _offset = 0
    }

    func setTail() {
        _offset = _papers.count - 1
    }
}