//
//  NovelReaderTests.swift
//  NovelReaderTests
//
//  Created by kang on 3/14/16.
//  Copyright © 2016 ruikyesoft. All rights reserved.
//

import XCTest
@testable import NovelReader

class NovelReaderTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testReadRange() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.

        dispatch_async(dispatch_queue_create("ready_to_open_book", nil)) {
            let filePath = NSBundle.mainBundle().pathForResource("zx_utf8", ofType: "txt")
            let book     = try! Book(fullFilePath: filePath!)
            let file     = fopen(filePath!, "r")
            let reader   = FileReader()

            let range = NSMakeRange(1024, FileReader.BUFFER_SIZE)
            let result = reader.readWithRange(file, range: range, encoding: FileReader.Encodings[book.encoding]!)

            XCTAssertTrue(range.loc == result.1.loc && range.end == result.1.end, "In:\(range) == Out:\(result.1)")

            fclose(file)
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
