//
//  VideoPreviewerH264ParserTests.swift
//  VideoPreviewerParserTests
//
//  Created by CmST0us on 2018/5/12.
//  Copyright © 2018年 eric3u. All rights reserved.
//

import XCTest

class VideoPreviewerH264ParserTests: XCTestCase {
    
    var parser: VideoPreviewerH264Parser!
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func tearDown() {

        super.tearDown()
    }
    
}

// MARK: - H264Parser Inital Tests
extension VideoPreviewerH264ParserTests {
    func testInitParserAndFree() {
        self.parser = VideoPreviewerH264Parser()
        self.parser.initial()
        self.parser.free()
    }
    func testParserReset() {
        self.parser = VideoPreviewerH264Parser()
        self.parser.initial()
        self.parser.reset()
    }
}


// MARK: - H264Parser Parser Tests
extension VideoPreviewerH264ParserTests {
    
    func testParserParserVideoTest() {
        self.parser = VideoPreviewerH264Parser()
        self.parser.initial()
        let data = NSData.init(contentsOfFile: "/Users/cmst0us/Desktop/test.h264")!
        let mutablePtr = UnsafeMutableRawBufferPointer.init(start: UnsafeMutableRawPointer(mutating: data.bytes), count: data.length)
        var uselen: Int = 0
        let res = self.parser.parser(mutablePtr, usedLength: &uselen)
        let w = res?.frameInfo.width
        let h = res?.frameInfo.height
        
        
    }
}
