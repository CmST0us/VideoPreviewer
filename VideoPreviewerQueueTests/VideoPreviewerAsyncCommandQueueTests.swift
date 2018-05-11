//
//  VideoPreviewerAsyncCommandQueueTests.swift
//  VideoPreviewerQueueTests
//
//  Created by CmST0us on 2018/5/11.
//  Copyright © 2018年 eric3u. All rights reserved.
//

import XCTest

class VideoPreviewerAsyncCommandQueueTests: XCTestCase {
    
    var testQueue: VideoPreviewerAsyncCommandQueue!
    var threadSafeTestQueue: VideoPreviewerAsyncCommandQueue!
    
    var productThread: Thread!
    var consumerThread: Thread!
    
    override func setUp() {
        super.setUp()
        
        self.testQueue              = VideoPreviewerAsyncCommandQueue(isThreadSafe: false)
        self.threadSafeTestQueue    = VideoPreviewerAsyncCommandQueue(isThreadSafe: true)
        
        self.productThread = Thread(target: self, selector: #selector(self.productThreadRunLoop), object: nil)
        self.productThread.name = "productThread"
        self.consumerThread = Thread(target: self, selector: #selector(self.consumerThreadRunLoop), object: nil)
        self.consumerThread.name = "consumer"
        
        self.productThread.start()
    }
    
    override func tearDown() {
        self.testQueue.cancelAllCommand()
        self.threadSafeTestQueue.cancelAllCommand()
        
        self.productThread.cancel()
        self.consumerThread.cancel()
    }
    
    @objc
    func productThreadRunLoop() {
        while !Thread.current.isCancelled {
            self.testQueue.startRunLoop(timeout: 2)
        }
        print("ProductThread End")
    }
    
    @objc
    func consumerThreadRunLoop() {
        
    }
    
}


// MARK: - Thread Unsafe Test Cases
extension VideoPreviewerAsyncCommandQueueTests {
    func testSinglePush() {
        let command = VideoPreviewerAsyncCommand(withTag: nil) { (hint) in
            switch hint {
            case .initial:
                    print("initial")
            case .needCancel:
                    print("need cancel")
            case .normal:
                    print("normal")
            }
        }
        self.testQueue.push(command, options: .fifo)
        
        RunLoop.current.run(until: Date.init(timeIntervalSinceNow: 5))
    }
    
    func  testRemovePush() {
        
    }
}


