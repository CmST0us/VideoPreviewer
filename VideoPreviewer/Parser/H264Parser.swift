//
//  H264Parser.swift
//  VideoPreviewer
//
//  Created by CmST0us on 2018/5/11.
//  Copyright © 2018年 eric3u. All rights reserved.
//

import Foundation
import ffmpeg

public protocol H264ParserDelegate {
    func parser(_ parser: H264Parser, didParseFrame frame: VideoFrame.H264)
    func parserDidFoundSpsPps(_ parser: H264Parser)
}

open class H264Parser {
    
    // MARK: - Public Member
    /// 精确的帧率
    public var frameRate: Int {
        if self.frameInterval != 0 {
            return Int(ceil(1.0 / self.frameInterval))
        }
        return 0
    }
    
    /// 帧间时间间隔
    public var frameInterval: TimeInterval {
        if self.codecParserContext != nil {
            return 0
        }
        
        return 0
    }
    
    /// 从上一次重置后的帧数计数
    public private(set) var frameCounter: UInt32!
    
    /// 输出视频的宽
    public var outputWidth: Int {
        if self.codecParserContext != nil {
            return Int(self.codecParserContext.pointee.width)
        }
        return 0
    }
    /// 输出视频的高
    public var outputHeight: Int {
        if self.codecParserContext != nil {
            return Int(self.codecParserContext.pointee.height)
        }
        return 0
    }
    
    
    public var shouldVerifyVideoStream: Bool
    
    public var delegate: H264ParserDelegate?
    
    // MARK: - Internal Member
    typealias AVCodecContextPtr = UnsafeMutablePointer<AVCodecContext>
    typealias AVCodecParserContextPtr = UnsafeMutablePointer<AVCodecParserContext>
    typealias AVCodecPtr = UnsafeMutablePointer<AVCodec>
    
    var codecContext: AVCodecContextPtr!
    var codecParserContext: AVCodecParserContextPtr!
    var codec: AVCodecPtr!
    
    // MARK: - Private Member
    private var frameUUIDCounter: UInt32 = 0
    private var parserLock: NSLock
    
    // MARK: - Inital And Deinital Method
    public init() {
        self.parserLock = NSLock()
        self.shouldVerifyVideoStream = true
        self.initial()
    }
    
    deinit {
        self.free()
    }
}

// MARK: - Public Method
extension H264Parser {
    public func initial() {
        self.parserLock.lock()
        
        self.frameCounter = 0
        self.frameUUIDCounter = 0
        
        // 创建 ffmpeg parser
        av_register_all()
        
        self.codec = avcodec_find_decoder(AV_CODEC_ID_H264)
        assert(self.codec != nil, "can not find decoder")
        
        self.codecParserContext = av_parser_init(Int32(self.codec.pointee.id.rawValue))
        self.codecContext = avcodec_alloc_context3(UnsafePointer(self.codec))
        
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
    
    public func parse(_ data: UnsafeMutableRawBufferPointer, usedLength: inout Int) {
        
        if self.codecContext == nil {
            usedLength = 0
            return
        }
        
        self.parserLock.lock()
        
        var dataLength = Int32(data.count)
        var parserLen: Int32 = 0
        usedLength = 0
        
        let bufSize = data.count + Int(FF_INPUT_BUFFER_PADDING_SIZE)
        let bufAddress = UnsafeMutableRawBufferPointer.allocate(byteCount: bufSize, alignment: MemoryLayout<UInt8>.alignment)
        // The end of the input buffer buf should be set to 0 to ensure that no overreading happens for damaged MPEG streams.
        memset(bufAddress.baseAddress, 0, bufSize)
        
        bufAddress.copyMemory(from: UnsafeRawBufferPointer.init(data))
        var feedBuf = bufAddress.bindMemory(to: UInt8.self).baseAddress!
        
        var outputFrame: VideoFrame.H264?
        
        var packet: UnsafeMutablePointer<AVPacket>? = av_packet_alloc()
        

        while dataLength > 0 {

            var packetData: UnsafeMutablePointer<UInt8>?
            var packetSize: Int32 = 0
            
            parserLen = av_parser_parse2(
                self.codecParserContext,
                self.codecContext,
                &packetData,
                &packetSize,
                feedBuf,
                dataLength,
                AV_NOPTS_VALUE,
                AV_NOPTS_VALUE,
                0)
            
            // c 函数通过指针访问Swift的结构体时，由于函数没有标记mutable，所以只有只读访问权限
            // 讲获取到的变量赋值给packet
            packet!.pointee.size = packetSize
            packet!.pointee.data = packetData
            
            dataLength -= parserLen
            feedBuf = feedBuf.advanced(by: Int(parserLen))
            
            usedLength += Int(parserLen)
            
            if packet!.pointee.size > 0 {
                
                // [TODO] hack code??
                if self.codecParserContext.pointee.height == 1088 {
                    self.codecParserContext.pointee.height = 1080
                }
                
                // 取出帧的宽高, 改为计算属性
                // [TODO] 468 × 212， 这是原视频的尺寸，上面那个hack估计是为了解决这个问题，ffmpeg命令行用码流创建后可以恢复468 x 212
                
                // 判断是否找到SPS或PPS帧
                
                // 计算帧率，改为计算属性
                
                // 标记没有sps和pps的帧需要校验
                
                /// 构建outputFrame
                let pc = self.codecParserContext!
                let _ = self.popNextFrameUUID()
                
                outputFrame = VideoFrame.H264()

                outputFrame!.frameData = packetData
                outputFrame!.typeTag = .videoFrameH264Raw
                outputFrame!.frameUUID = self.frameUUIDCounter
                outputFrame!.frameSize = UInt32(packet!.pointee.size)
            
                outputFrame!.frameInfo.frameIndex = pc.pointee.output_picture_number

                
                if pc.pointee.height == 1088 {
                    pc.pointee.height = 1080
                }
                
                outputFrame!.frameInfo.framePoc = pc.pointee.output_picture_number
                outputFrame!.frameInfo.width = pc.pointee.width
                outputFrame!.frameInfo.height = pc.pointee.height
                outputFrame!.frameInfo.fps = UInt16(self.frameRate)
                outputFrame!.frameInfo.frameFlag.hasIDR = pc.pointee.key_frame == 1
                outputFrame!.frameInfo.frameFlag.isFullRange = false
                
                // [TODO] 这个shouldVerifyVideoStream还有点问题
                if outputFrame != nil {
                    self.frameCounter = self.frameCounter + UInt32(1)
                    if self.delegate != nil {
                        self.delegate!.parser(self, didParseFrame: outputFrame!)
                    }
                }
                
            }
        }
        // 释放资源
        av_packet_free(&packet)

        bufAddress.deallocate()
        self.parserLock.unlock()
    }
    
    func popNextFrameUUID() -> UInt32 {
        self.frameUUIDCounter = self.frameUUIDCounter + UInt32(1)
        if self.frameUUIDCounter == H264_FRAME_INVAILED_UUID {
            self.frameUUIDCounter = self.frameUUIDCounter + UInt32(1)
        }
        return self.frameUUIDCounter
        
    }
}
