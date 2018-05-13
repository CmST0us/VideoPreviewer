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
    var fps: Int = 0
    var frameCount: Int = 0
    var fpsTimer: Timer!
    var timerThread: Thread!
    
    override func setUp() {
        super.setUp()
        decoder = H264SoftwareDecoder()
        decoder.initial()
        decoder.delegate = self
        
        self.timerThread = Thread.init(block: { [weak self] in
            
            self!.fpsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer) in
                self!.fps = self!.frameCount
                self!.frameCount = 0
            })
            
            while !Thread.current.isCancelled {
                RunLoop.current.run(until: Date.init(timeIntervalSinceNow: 2.0))
            }
            
        })
        
        self.timerThread.start()
        
        XCTAssert(decoder.open(), "decoder can not open")
    }
    
    override func tearDown() {
        super.tearDown()
        decoder.close()
        decoder.free()
        self.timerThread.cancel()
        self.fpsTimer.invalidate()
        self.fpsTimer = nil
    }
    
    
    func testDecode() {
        let data = NSData.init(contentsOfFile: "/Users/cmst0us/Desktop/swift.h264")!
        let mutablePtr = UnsafeMutableRawBufferPointer.init(start: UnsafeMutableRawPointer(mutating: data.bytes), count: data.length)
        var uselen: Int = 0
        self.decoder.parser.parse(mutablePtr, usedLength: &uselen)
    }
    
}

extension H264DecoderTests: H264SoftwareDecoderDelegate {
    func decoder(_ decoder: H264SoftwareDecoder, didGotPicture picture: VideoFrame.YUV) {
        let w = Int(picture.width)
        let h = Int(picture.height)
        let s = Int(picture.frameInfo.frameIndex)
        self.frameCount += 1
        let mes = """
        fps (\(String(self.fps))) Frame got:
            w = \(String(w))
            h = \(String(h))
            s = \(String(s))
        """
        print(mes)
        if let cvImage = picture.getYUV420PCVImage() {
            let ciImage = CIImage.init(cvPixelBuffer: cvImage)
            let image = UIImage.init(ciImage: ciImage)
            print(image.debugDescription)
            
        }
        
    }
}
