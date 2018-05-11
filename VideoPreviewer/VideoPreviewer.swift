//
//  VideoPreviewer.swift
//  ViewPreviewer
//
//  Created by CmST0us on 2018/5/10.
//  Copyright © 2018年 eric3u. All rights reserved.
//

import Foundation
import OpenGLES

struct VideoPreviewerStatus {
    var isInit: Bool = false // true when VideoPreviewer is initialized
    var isRunning: Bool = false // true when the decoding thread is running
    var isPause: Bool = false // true when the decoder is pause
    var isFinish: Bool = false // true when it is finish
    var hasImage: Bool = false // true when it has image
    var isGLViewInit: Bool = false // true when the GLView is initialized
    var isBackground: Bool = false // true when ViewPreviewer is in background
    var other: UInt8 = 0 // reserved
}

enum VideoDecoderStatus {
    case normal // normal status
    case noData // no data
    case decoderError // decode error
}

enum VideoPreviewerEvent {
    case noImage // decode no image
    case hasImage // decode has image
    case resumeReady // after safe resume, resume decode
}

enum VideoPreviewerType {
    case autoAdapt // auto adjust to adapt size
    case fullWindow // full window
    case none // none
}

let kVideoPreviewerQueueName = "video_previewer_async_queue"
let kVideoPreviewerDispatch = "video_preview_create_thread_dispatcher"
let kVideoPreviewerEventNotification = "video_preview_even_notification"

public class VideoPreviewer {
    
    public static let previewer = VideoPreviewer()
    
    // MARK: - Public
    public var dataQueue: VideoPreviewerQueue
    
    // MARK: Data Input
    public var isPerformanceCountEnabled: Bool
    
    // MARK: Geometry
    // VideoPreviewer的显示类型
    // 注意只能在主线程调用
    var type: VideoPreviewerType
    
    //
    public var isDefaultPreviewer: Bool
    
    var dispatchQueue: DispatchQueue
    
    
    // MARK: - Private
    // 解码线程
    private var decodeThread: Thread!
    
    // OpenGL 渲染视图
    private var glView: MovieGLView!
    
    
    var decoderStatus: VideoDecoderStatus
    
    
    
//    var streamProcessorList
    
//    var frameProcessorList
    
    var luminanceScale: Double
    
    var isEnableFastUpload: Bool
    
    var safeResumeSkipCount: Bool
    
    var renderCond: NSCondition
    
    var isRendering: Bool
    
    var decodeRunloopBlocker: NSLock
    
//    var cmdQueue
    
//    var videoExxtractor
    
//    var processorMutex
    
//    var status
    
//    var streamBasicInfo
    
//    var softDecoder
    
//    var hardDecoder
    
//    var encoderType
    
//    var lb2AUDRemove
    
    var isEnableHardwareDecode: Bool
    
    
    // MARK: - Init And Deinit Method
    public convenience init() {
        self.init(defaultPreviewer: true)
    }
    
    public init(defaultPreviewer: Bool) {
        // 设置是否是默认预览器
        self.isDefaultPreviewer = defaultPreviewer
        
        // Swift中默认是串行队列
        self.dispatchQueue = DispatchQueue(label: kVideoPreviewerQueueName)
        
        self.isPerformanceCountEnabled      = false
        self.decodeThread       = nil
        self.glView             = nil
        self.type               = .autoAdapt
        self.decoderStatus      = .normal
        
        self.dataQueue = VideoPreviewerQueue(withSize: 100)
        
        
        // [TODO] 添加进入后台和重新进入前台的唤醒
        // NotificationCenter
        // UIApplicationWillResignActiveNotification
        // UIApplicationDidBecomeActiveNotification
        
#if !TARGET_IPHONE_SIMULATOR
        // 判断FoundationVersionNumber
        if NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1 {
            // 使用硬件解码器
            self.isEnableHardwareDecode = true
        }
        
        // [TODO] 注册解码器
        
        
#endif
        
    }

    deinit {
        
    }
    
}


extension VideoPreviewer {
    
}
