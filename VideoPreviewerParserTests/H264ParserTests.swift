//
//  H264ParserTests.swift
//  VideoPreviewerParserTests
//
//  Created by CmST0us on 2018/5/12.
//  Copyright © 2018年 eric3u. All rights reserved.
//

import XCTest

class H264ParserTests: XCTestCase {
    
    var parser: H264Parser!
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func tearDown() {

        super.tearDown()
    }
    
}

// MARK: - H264Parser Inital Tests
extension H264ParserTests {
    func testInitParserAndFree() {
        self.parser = H264Parser()
        self.parser.initial()
        self.parser.free()
    }
    func testParserReset() {
        self.parser = H264Parser()
        self.parser.initial()
        self.parser.reset()
    }
}


// MARK: - H264Parser Parser Tests
extension H264ParserTests: H264ParserDelegate {
    
    func testParserParserVideoTest() {
        self.parser = H264Parser()
        self.parser.delegate = self
        self.parser.initial()
        let data = NSData.init(contentsOfFile: "/Users/cmst0us/Desktop/test.h264")!
        let mutablePtr = UnsafeMutableRawBufferPointer.init(start: UnsafeMutableRawPointer(mutating: data.bytes), count: data.length)
        var uselen: Int = 0
        self.parser.parser(mutablePtr, usedLength: &uselen)
    }
    
    func parser(_ parser: H264Parser, didParseFrame frame: VideoFrame.H264) {
        let outputMessage = """
Frame \(String(frame.frameInfo.frameIndex)) fps: \(String(parser.frameRate)) :
        \(String(parser.outputWidth)) x \(String(parser.outputHeight)) \(String(frame.frameSize)) Byte
"""
        print(outputMessage)
    }
}
