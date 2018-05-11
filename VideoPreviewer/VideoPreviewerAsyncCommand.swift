//
//  VideoPreviewerAsyncCommand.swift
//  VideoPreviewer
//
//  Created by CmST0us on 2018/5/11.
//  Copyright © 2018年 eric3u. All rights reserved.
//

import Foundation

public class VideoPreviewerAsyncCommand {
    
    /// 命令执行前的上下文环境
    ///
    /// - initial: 还未执行 [TODO]这个选项还没用到，后面尝试在讲任务添加到队列中时调用
    /// - normal: 正常执行
    /// - needCancel: 被取消
    public enum Hint {
        case initial
        case normal
        case needCancel
    }
    
    
    public typealias Operation = (_ hint: VideoPreviewerAsyncCommand.Hint) -> Void
    
    /// 是否需要回调，如果true,即便cancel了一会回调,只是hint会变成.needCancel
    public var isAlwaysNeedCallback: Bool
    
    /// 回调block
    public var workBlock: VideoPreviewerAsyncCommand.Operation?
    
    /// 用于识别此任务
    public var tag: AnyObject?
    
    /// 运行延时
    public var runAfterDate: Date?
    
    // 控制任务是否结束
    public var cancelMark: Bool
    
    // MARK: - Initial Method And Deinital Method
    public convenience init(withTag tag: AnyObject?, block: VideoPreviewerAsyncCommand.Operation?) {
        self.init(withTag: tag, afterDate: nil, block: block)
    }
    
    public init(withTag tag: AnyObject?, afterDate: Date?, block: VideoPreviewerAsyncCommand.Operation?) {
        self.tag = tag
        self.workBlock = block
        self.runAfterDate = afterDate
        self.isAlwaysNeedCallback = true
        self.cancelMark = false
    }
}

