//
//  VideoPreviewerH264Parser.swift
//  VideoPreviewer
//
//  Created by CmST0us on 2018/5/11.
//  Copyright © 2018年 eric3u. All rights reserved.
//

import Foundation
import ffmpeg

open class VideoPreviewerH264Parser: VideoPreviewerParser {
    // MARK: - Public Member
    // DJI Product used
//    public var usingDJIAircraftEncoder: Bool
    
    /// 精确的帧率
    public private(set) var frameRate: Int!
    
    /// 从上一次重置后的帧数计数
    public private(set) var frameCounter: UInt32!
    
    /// 输出视频的宽
    public var outputWidth: Int!
    /// 输出视频的高
    public var outputHeight: Int!
    
    public var shouldVerifyVideoStream: Bool!
    
    /// 帧间时间间隔
    public private(set) var frameInterval: TimeInterval!
    
    // MARK: - Internal Member
    private var frameUUIDCounter: UInt32 = 0
    typealias AVCodecContextPtr = UnsafeMutablePointer<AVCodecContext>
    typealias AVCodecParserContextPtr = UnsafeMutablePointer<AVCodecParserContext>
    private var codecContext: AVCodecContextPtr!
    private var codecParserContext: AVCodecParserContextPtr!
    private var parserLock: NSLock
    
    
    // MARK: - Inital And Deinital Method
    public init() {
        self.parserLock = NSLock()
        self.initial()
    }
    
    deinit {
        self.free()
    }
}

// MARK: - Public Method
extension VideoPreviewerH264Parser {
    public func initial() {
        self.parserLock.lock()
        
        self.frameRate = 0
        self.frameInterval = 0
        self.frameCounter = 0
        self.frameUUIDCounter = 0
        self.outputWidth = 0
        self.outputHeight = 0
        
        // 创建 ffmpeg parser
        av_register_all()
        let pCodec = avcodec_find_decoder(AV_CODEC_ID_H264)
        assert(pCodec != nil, "can not find decoder")
        self.codecContext = avcodec_alloc_context3(UnsafePointer(pCodec!))
        self.codecParserContext = av_parser_init(Int32(AV_CODEC_ID_H264.rawValue))
        
        self.parserLock.unlock()
    }
    
    public func free() {
        self.parserLock.lock()
        
        if self.codecContext != nil {
            
            avcodec_close(self.codecContext)
            av_freep(&self.codecContext)
        }
        
        if self.codecParserContext != nil {
            av_parser_close(self.codecParserContext)
            // 文档建议使用av_freep,可以在,并且ptr == nil 的情况时被允许的
            av_freep(&self.codecContext)
        }
        
        self.parserLock.unlock()
    }
    
    public func reset() {
        if self.codecContext != nil {
            self.free()
        }
        self.initial()
    }
    
    public func parser(_ data: UnsafeMutableRawBufferPointer, usedLength: inout Int) -> VideoFrame.H264? {
        
        if self.codecContext == nil {
            usedLength = 0
            return nil
        }
        
        self.parserLock.lock()
        
        var parserInLength = Int32(data.count)
        var parserLen: Int32 = 0
        usedLength = 0
        
        var buf = data.bindMemory(to: UInt8.self).baseAddress!
        var outputFrame: VideoFrame.H264?
        
        while parserInLength > 0 {
            
            var packet: AVPacket?
            av_init_packet(&packet!)

            var packetData = packet!.data
            var packetSize = packet!.size
            
            parserLen = av_parser_parse2(
                self.codecParserContext,
                self.codecContext,
                &(packetData),
                &(packetSize),
                buf,
                parserInLength,
                Int64(AV_NOPTS_VALUE),
                Int64(AV_NOPTS_VALUE),
                Int64(AV_NOPTS_VALUE))
            
            parserInLength -= parserLen
            buf = buf.advanced(by: Int(parserLen))
            
            usedLength += Int(parserLen)
            
            if packet!.size > 0 {
                var isSpsPpsFound = false
                
                // [TODO] hack code??
                if self.codecParserContext.pointee.height_in_pixel == 1088 {
                    self.codecParserContext.pointee.height_in_pixel = 1080
                }
                
                // [TODO] 可以使用计算属性
                // 取出帧的宽高
                self.outputWidth = Int(self.codecParserContext.pointee.width_in_pixel)
                self.outputHeight = Int(self.codecParserContext.pointee.height_in_pixel)
                
                // 判断是否找到SOS或PPS帧
                isSpsPpsFound = self.codecParserContext.pointee.frame_has_pps > 0
                
                // 计算帧率
                if self.codecParserContext.pointee.frame_rate_den > 0 && self.codecParserContext.pointee.frame_rate_num > 0 {
                    
                    // using by DJI Encoder
//                    var scale = self.usingAJIAircraftEncoder ? 2.0 : 1.0
                    
                    self.frameInterval = Double(self.codecParserContext.pointee.frame_rate_den) / Double(self.codecParserContext.pointee.frame_rate_num)
                    self.frameRate = Int(ceil(1.0 / self.frameInterval))
                    
                } else {
                    self.frameRate = 0
                    self.frameInterval = 0
                }
                
                // 标记没有sps和pps的帧需要校验
                if self.shouldVerifyVideoStream {
                    if isSpsPpsFound {
                        self.shouldVerifyVideoStream = false
                    } else {
                        continue
                    }
                }
                
                
                let _ = self.popNextFrameUUID()
                outputFrame = VideoFrame.H264()
                outputFrame!.typeTag = .videoFrameH264Raw
                outputFrame!.frameUUID = self.frameUUIDCounter
                outputFrame!.frameSize = UInt32(packet!.size)
            
                /// 构建outputFrame
                let pc = self.codecParserContext!
                outputFrame!.frameInfo.frameIndex = pc.pointee.frame_num
                outputFrame!.frameInfo.maxFrameIndexPlusOne = pc.pointee.max_frame_num_plus1
                
                if outputFrame!.frameInfo.frameIndex >= outputFrame!.frameInfo.maxFrameIndexPlusOne {
                    // Never Cound Run Here
                }
                
                if pc.pointee.height_in_pixel == 1088 {
                    pc.pointee.height_in_pixel = 1080
                }
                
                outputFrame!.frameInfo.framePoc = pc.pointee.output_picture_number
                outputFrame!.frameInfo.width = pc.pointee.width_in_pixel
                outputFrame!.frameInfo.height = pc.pointee.height_in_pixel
                outputFrame!.frameInfo.fps = UInt16(self.frameRate)
                outputFrame!.frameInfo.frameFlag.hasSPS = pc.pointee.frame_has_sps > 0
                outputFrame!.frameInfo.frameFlag.hasPPS = pc.pointee.frame_has_pps > 0
                outputFrame!.frameInfo.frameFlag.hasIDR = pc.pointee.key_frame == 1
                outputFrame!.frameInfo.frameFlag.isFullRange = false
                
            }
            // 释放资源
            av_free_packet(&packet!)
            
            if outputFrame != nil {
                break
            }
        }
        
        if outputFrame != nil {
            self.frameCounter = self.frameCounter + UInt32(1)
        }
        
        self.parserLock.unlock()
        return outputFrame
    }
    
    func popNextFrameUUID() -> UInt32 {
        self.frameUUIDCounter = self.frameUUIDCounter + UInt32(1)
        if self.frameUUIDCounter == H264_FRAME_INVAILED_UUID {
            self.frameUUIDCounter = self.frameUUIDCounter + UInt32(1)
        }
        return self.frameUUIDCounter
        
    }
}
