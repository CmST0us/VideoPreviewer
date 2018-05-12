//
//  H264DecoderTests.swift
//  VideoPreviewerParserTests
//
//  Created by CmST0us on 2018/5/12.
//  Copyright © 2018年 eric3u. All rights reserved.
//

import XCTest

class H264DecoderTests: XCTestCase {
    
    var decoder: H264SoftwareDecoder!
    
    override func setUp() {
        super.setUp()
        decoder = H264SoftwareDecoder()
        decoder.initial()
        decoder.open()
    }
    
    override func tearDown() {
        
        super.tearDown()
    }
    
    
    func testDecode() {
        let data = NSData.init(contentsOfFile: "/Users/cmst0us/Desktop/test.h264")!
        let mutablePtr = UnsafeMutableRawBufferPointer.init(start: UnsafeMutableRawPointer(mutating: data.bytes), count: data.length)
        var uselen: Int = 0
        self.decoder.h264Parser.parse(mutablePtr, usedLength: &uselen)
    }
    
}
