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
        decoder.delegate = self
        decoder.open()
    }
    
    override func tearDown() {
        super.tearDown()
        decoder.close()
        decoder.free()
        
    }
    
    
    func testDecode() {
        let data = NSData.init(contentsOfFile: "/Users/cmst0us/Desktop/swift.h264")!
        let mutablePtr = UnsafeMutableRawBufferPointer.init(start: UnsafeMutableRawPointer(mutating: data.bytes), count: data.length)
        var uselen: Int = 0
        self.decoder.h264Parser.parse(mutablePtr, usedLength: &uselen)
    }
    
}

extension H264DecoderTests: H264SoftwareDecoderDelegate {
    func decoder(_ decoder: H264SoftwareDecoder, didGotPicture picture: H264SoftwareDecoder.AVFramePtr) {
        let w = Int(picture.pointee.width)
        let h = Int(picture.pointee.height)
        let s = Int(picture.pointee.pkt_size)
        
        let mes = """
        Frame got:
        w = \(String(w))
        h = \(String(h))
        s = \(String(s))
        """
        print(mes)
    }
}
