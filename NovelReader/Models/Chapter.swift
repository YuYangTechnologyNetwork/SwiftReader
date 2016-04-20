//
//  Chapter.swift
//  NovelReader
//
//  Created by kangyonggen on 4/20/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import Foundation

class Chapter: BookMark {
    private(set) var papers: [Paper]?
    private(set) var loading: Bool = true

    override init(title: String, range: NSRange) {
        super.init(title: title, range: range)
    }

    func asyncLoadInRange(readerMgr: ReaderManager, book: Book, range: NSRange, callback: (_: Bool) -> Void) {
        dispatch_async(dispatch_queue_create(Constants.GLOBAL_ASYNC_QUEUE_NAME, nil)) {
            self.loading = true
            let file = fopen((book.fullFilePath), "r")
            let encoding = FileReader.Encodings[book.encoding]
            let reader = FileReader()
            let chapters = reader.chaptersInRange(file, range: NSMakeRange(0, 20480), encoding: encoding!)
            let ready = chapters.count > 0

            if ready {
                let content = reader.readRange(file, range: chapters[0].range, encoding: encoding!)
                self.papers = readerMgr.papersWithContent(content!,
                                                          firstListIsTitle: chapters[0].title != Constants.NO_TITLE)
            }

            fclose(file)
            dispatch_async(dispatch_get_main_queue()) {
                self.loading = false
                callback(_: ready)
            }
        }
    }
}