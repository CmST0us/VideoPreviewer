//
//  ViewPreviewerQueueTests.swift
//  ViewPreviewerQueueTests
//
//  Created by CmST0us on 2018/5/10.
//  Copyright © 2018年 eric3u. All rights reserved.
//

import XCTest

class ViewPreviewerQueueTests: XCTestCase {
    
    var testQueue: VideoPreviewerQueue!
    
    var mockData = [1, 2, 3, 4, 5, 6]
    
    var productThread: Thread!
    
    var consumerThread: Thread!
    
    override func setUp() {
        super.setUp()
        
        self.testQueue = try? VideoPreviewerQueue(withSize: 100)
        XCTAssert(self.testQueue != nil, "Init VideoPreviewerQueue Error")
        self.productThread = Thread(target: self, selector: #selector(productRunLoop), object: nil)
        self.consumerThread = Thread(target: self, selector: #selector(consumerRunLoop), object: nil)
        
    }
    
    override func tearDown() {
        super.tearDown()
        self.productThread.cancel()
        self.consumerThread.cancel()
        self.testQueue = nil
    }
    
    @objc
    func productRunLoop() {
        
        while !Thread.current.isCancelled {
            RunLoop.current.run(until: Date.init(timeIntervalSinceNow: 1.0))
            print("Product RunLoop End")
        }
    }
    
    @objc
    func consumerRunLoop() {
        
        while !Thread.current.isCancelled {
            RunLoop.current.run(until: Date.init(timeIntervalSinceNow: 1.0))
            print("Consumer RunLoop End")
        }
        
    }
    
    func pushOne() -> Bool {
        // data 不持有对象，应先拷贝,而且应该在with这里拷贝返回拷贝后的数据
        let data = UnsafeRawBufferPointer.init(mockData.withUnsafeBufferPointer({ (ptr) -> UnsafeRawBufferPointer in
            let bufferLen = ptr.count * MemoryLayout<Int>.alignment
            let allocRawPointer = UnsafeMutableRawPointer.allocate(byteCount: bufferLen, alignment: 1)
            allocRawPointer.copyMemory(from: ptr.baseAddress!, byteCount: bufferLen)
            let buf = UnsafeRawBufferPointer.init(start: UnsafeRawPointer(allocRawPointer), count: bufferLen)
            return buf
        }))
        print("address: \(String(data.debugDescription))")
        return self.testQueue.push(data)
    }
    
    func pullOne() -> UnsafeRawBufferPointer? {
        return self.testQueue.pull()
    }
}


// MARK: - Single Thread Test Cases
extension ViewPreviewerQueueTests {
    
    func testSinglePushAndPull() {
        let _ = pushOne()
        XCTAssert(pullOne() != nil, "Pull Buffer Error")
    }
    
    func testSinglePushAndMultiPull() {
        let _ = pushOne()
        let _ = pullOne()
        XCTAssert(pullOne() == nil, "Pull Buffer Error When Queue Empty")
    }
    
    func testMultiPushAndCheckFull() {
        for i in 0 ..< 100 {
            let _ = pushOne()
            print("\(String(i))")
        }
        XCTAssert(self.testQueue.isFull, "Check is Full Error")
    }
    
    func testBigPush() {
        for i in 0 ..< 200 {
            let _ = pushOne()
            print("\(String(i))")
        }
    }
}
