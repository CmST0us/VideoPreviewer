//
//  VideoPreviewerAsyncCommandQueue.swift
//  VideoPreviewer
//
//  Created by CmST0us on 2018/5/11.
//  Copyright © 2018年 eric3u. All rights reserved.
//

import Foundation

/// 异步命令队列，相当于RunLoop的行为可以异步插入，读取，定义不同的命令插入规则
public class VideoPreviewerAsyncCommandQueue {
    
    public struct Option: OptionSet {
        public let rawValue: Int
        
        public static let fifo = VideoPreviewerAsyncCommandQueue.Option(rawValue: 0) // 正常队列
        public static let lifo = VideoPreviewerAsyncCommandQueue.Option(rawValue: 1) // 优先出列
        public static let removeSameTag = VideoPreviewerAsyncCommandQueue.Option(rawValue: 1 << 1) // 清除相同tag
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    
    // MARK: - Private Member
    private var lock: NSCondition
    private var isThreadSafe: Bool
    private var commandArray: [VideoPreviewerAsyncCommand]
    
    // MARK: - Initial Method And Deinital Method
    public init(isThreadSafe: Bool) {
        self.isThreadSafe = isThreadSafe
        self.lock = NSCondition.init()
        self.commandArray = []
    }
    
    deinit {
        
    }
}

// MARK: - Public Method
extension VideoPreviewerAsyncCommandQueue {
    
    /// 添加命令
    ///
    /// - Parameters:
    ///   - command: 命令对象
    ///   - options: 选项
    public func push(_ command: VideoPreviewerAsyncCommand, options: VideoPreviewerAsyncCommandQueue.Option) {
        
        if self.isThreadSafe {
            self.lock.lock()
        }
        
        // 移除之前的命令
        if options.contains(.removeSameTag) {
            self.commandArray.forEach { (obj) in
                if obj.tag?.isEqual(command.tag) ?? false {
                    obj.cancelMark = true
                }
            }
        }
        
        // 插入队列前面
        if options.contains(.lifo) {
            self.commandArray.insert(command, at: 0)
        } else {
            self.commandArray.append(command)
        }
        
        self.lock.signal()
        if self.isThreadSafe {
            self.lock.unlock()
        }
    }
    
    /// 开始循环处理任务队列
    ///
    /// - Parameter timeout: 取指令超时事件，默认0
    public func startRunLoop(timeout: TimeInterval = 0) {
        
        if self.isThreadSafe {
            self.lock.lock()
        }
        
        if timeout == 0 || self.commandArray.count == 0 || !self.isThreadSafe {
            
        } else {
            // 等待拉取
            lock.wait(until: Date.init(timeIntervalSinceNow: timeout))
            if self.commandArray.count == 0 {
                // 没有指令
                self.lock.unlock()
                return
            }
        }
        
        // 取出运行的
        let runCommand = self.commandArray.enumerated().filter { (index, obj) -> Bool in
            return obj.runAfterDate == nil || obj.runAfterDate!.timeIntervalSinceNow <= 0
        }
        
        runCommand.forEach { (index, obj) in
            self.commandArray.remove(at: index)
        }
        
        if isThreadSafe {
            self.lock.unlock()
        }
        
        runCommand.forEach { (index, obj) in
            if obj.cancelMark {
                if obj.isAlwaysNeedCallback {
                    if let block = obj.workBlock {
                        block(.needCancel)
                    }
                }
            } else {
                if let block = obj.workBlock {
                    block(.normal)
                }
            }
        }
        
    }

    
    /// 将命令队列中tag和所给tag相同的命令标记为取消
    ///
    /// - Parameter tag: 用于区别一个命令
    public func cancelCommand(_ tag: AnyObject) {
        self.cancelCommand([tag])
    }
    
    
    /// 将命令队列中tag包含在tags中的所有任务标记为取消
    ///
    /// - Parameter tags: 用于区别一个命令
    public func cancelCommand(_ tags:[AnyObject]) {
        if self.isThreadSafe {
            self.lock.lock()
        }
        
        self.commandArray.forEach { (obj) in
            for tagObj in tags {
                if tagObj.isEqual(obj) {
                    obj.cancelMark = true
                    break
                }
            }
        }
        
        if self.isThreadSafe {
            self.lock.unlock()
        }
    }
    
    /// 将命令队列中所有命令标记为取消状态
    public func cancelAllCommand() {
        if self.isThreadSafe {
            self.lock.lock()
        }
        
        self.commandArray.forEach { (obj) in
            obj.cancelMark = true
        }
        
        if self.isThreadSafe {
            self.lock.unlock()
        }
    }
}

// MARK: - Private Method
extension VideoPreviewerAsyncCommandQueue {
}
