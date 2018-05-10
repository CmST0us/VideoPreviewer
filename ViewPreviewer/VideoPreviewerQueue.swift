//
//  VideoPreviewerQueue.swift
//  ViewPreviewer
//
//  Created by CmST0us on 2018/5/10.
//  Copyright © 2018年 eric3u. All rights reserved.
//

import Foundation

enum VideoPreviewQueueError: Error {
    case wrongSizeInput
}

struct VideoPreviewerQueueLinkNode {
    var ptr: UnsafeRawBufferPointer!
    var size: Int {
        if ptr != nil {
            return ptr.count
        }
        return 0
    }
}

public class VideoPreviewerQueue {
    
    // MARK: Public Member
    /// number of objects in queue
    public var count: Int
    
    /// size of the queue
    public var size: Int
    
    public var isFull: Bool {
        return self.count == self.size
    }
    
    // MARK: Private Member
    typealias VideoPreviewerQueueLinkNodeBufferPointer = UnsafeMutableBufferPointer<VideoPreviewerQueueLinkNode>
    private var node: VideoPreviewerQueueLinkNodeBufferPointer!
    private var head: Int
    private var tail: Int
    
    private var lock: NSCondition
    
    // MARK: Initial Method
    /// Create a queue object
    ///
    /// - Parameter size: the initial size
    public init(withSize size: Int) throws {
        
        if size <= 0 {
            throw VideoPreviewQueueError.wrongSizeInput
        }
        
        self.size = size
        self.count = 0
        self.head = 0
        self.tail = 0
        
        self.lock = NSCondition()
        
        // Alloc Memory For Node
        /*
        let allocatedMemoryPtr = UnsafeMutableRawPointer.allocate(
            byteCount: self.size * MemoryLayout<VideoPreviewerQueueLinkNodeBufferPointer>.stride,
            alignment: MemoryLayout<VideoPreviewerQueueLinkNodeBufferPointer>.alignment)

        let defaultNode = VideoPreviewerQueueLinkNode()
        self.node = allocatedMemoryPtr.initializeMemory(as: VideoPreviewerQueueLinkNode.self, repeating: defaultNode, count: self.count)
         
         这个方法有问题
         */
        let allocatedMemoryPtr = VideoPreviewerQueueLinkNodeBufferPointer.allocate(capacity: self.size)
        let defaultNode = VideoPreviewerQueueLinkNode()
        allocatedMemoryPtr.initialize(repeating: defaultNode)
        self.node = allocatedMemoryPtr
        
    }
    
    deinit {
        self.clear()
        self.node.deallocate()
        self.node = nil
    }
}

// MARK: - Public Method
extension VideoPreviewerQueue {
    public func clear() {
        self.lock.lock()
        var index = 0
        for i in 0 ..< self.count {
            if self.head + i >= self.size {
                // 从头开始
                index = self.head + i - self.size
            } else {
                index = self.head + i
            }
            if let p = self.node[index].ptr {
                p.deallocate()
                self.node[index].ptr = nil
            }
        }
        self.head = 0
        self.tail = 0
        self.lock.unlock()
    }
    
    public func push(_ buf: UnsafeRawBufferPointer) -> Bool {
        self.lock.lock()
        if buf.count == 0 || self.isFull {
            self.lock.unlock()
            buf.deallocate()
            return false
        }

        self.node[self.tail].ptr = buf
        self.tail += 1
        
        if self.tail >= self.size {
            self.tail = 0
        }
        
        self.count += 1
        self.lock.signal()
        self.lock.unlock()
        return true
    }
    
    public func pull() -> UnsafeRawBufferPointer? {
        self.lock.lock()
        if self.count == 0{
            // 重试1次拉取
            self.lock.wait(until: Date.init(timeIntervalSinceNow: 2.0))
            if self.count == 0 {
                // 没有数据拉取超时
                self.lock.unlock()
                return nil
            }
        }
        
        let p = self.node[self.head].ptr
        self.head += 1
        if (self.head >= self.size) {
            self.head = 0
        }
        
        self.count -= 1
        
        self.lock.unlock()
        
        return p
    }
    
    public func wakeupReader() {
        self.lock.lock()
        self.lock.signal()
        self.lock.unlock()
    }
    
}

// MARK: - Private Method
extension VideoPreviewerQueue {
    
}
