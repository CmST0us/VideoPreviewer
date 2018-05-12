//
//  H264SoftwareDecoder.swift
//  VideoPreviewer
//
//  Created by CmST0us on 2018/5/12.
//  Copyright © 2018年 eric3u. All rights reserved.
//

import Foundation
import ffmpeg

/// 使用ffmpeg的H264解码器
open class H264SoftwareDecoder {
    
    // MARK: - Public Member
    /// h264解析器
    public var h264Parser: H264Parser!
    
    
    // MARK: - Private Member
    typealias AVFramePtr = UnsafeMutablePointer<AVFrame>

    private var pFrame: AVFramePtr!
    private var frameInfoListCount: Int!
    private var frameInfoList: UnsafeMutableBufferPointer<VideoFrame.H264>!
    
    
    // MARK: - Internal Member
    init() {
        self.initial()
    }
    
}

// MARK: - Public Method
extension H264SoftwareDecoder {
    func initial() {
        
        // 初始化解析器
        self.h264Parser = H264Parser()
        self.h264Parser.delegate = self
        self.h264Parser.initial()
        
        self.pFrame = av_frame_alloc()

        // [WARNING] 探究一下这个标记
        self.h264Parser.codecContext.pointee.flags2 |= CODEC_FLAG2_FAST
        // decide how many independent tasks should be passed to execute()
        self.h264Parser.codecContext.pointee.thread_count = 2
        self.h264Parser.codecContext.pointee.thread_type = FF_THREAD_FRAME
        
        if (self.h264Parser.codec.pointee.capabilities & CODEC_FLAG_LOW_DELAY) > 0 {
            self.h264Parser.codecContext.pointee.flags |= CODEC_FLAG_LOW_DELAY
        }
        
        self.frameInfoListCount = 0
        self.frameInfoList = nil
    }
    
    func free() {
        objc_sync_enter(self)
        
        if self.pFrame != nil {
            av_freep(self.pFrame)
        }
        
        self.h264Parser.free()
        
        if self.frameInfoList != nil {
            self.frameInfoList.deallocate()
            self.frameInfoList = nil
            self.frameInfoListCount = 0
        }
        
        objc_sync_exit(self)
    }
    
    func open() -> Bool{
        var nullPtr: OpaquePointer? = nil
        return avcodec_open2(self.h264Parser.codecContext, self.h264Parser.codec, &nullPtr) == 0
    }
    
    func close() {
        avcodec_close(self.h264Parser.codecContext)
    }
    
    func decode(_ frame: VideoFrame.H264, block: (_ didGotPicture: Bool) -> Void) {
        objc_sync_enter(self)
        
        if frame.frameData != nil || frame.frameSize <= 0{
            block(false)
        }
        
        var packet = AVPacket()
        packet.data = frame.frameData
        packet.size = Int32(frame.frameSize)
        
        if self.frameInfoListCount > frame.frameInfo.frameIndex {
            let currentFrameIndex = Int(frame.frameInfo.frameIndex)
            self.frameInfoList[currentFrameIndex] = frame
        }
        
        var didGotPicture: Int32 = 0
        avcodec_decode_video2(self.h264Parser.codecContext, self.pFrame, &didGotPicture, &packet)
        
        if self.h264Parser.codecContext.pointee.height == 1088 {
            self.h264Parser.codecContext.pointee.height = 1080
        }
        
        if didGotPicture > 0 {
            block(true)
        }
        
        av_free_packet(&packet)
        
        objc_sync_exit(self)
    }
}

// MARK: - H264Parser Delegate
extension H264SoftwareDecoder: H264ParserDelegate {
    
    public func parserDidFoundSpsPps(_ parser: H264Parser) {
        if self.frameInfoListCount != parser.codecParserContext.pointee.max_frame_num_plus1 {
            // 重新创建 frame info list
            if self.frameInfoList != nil {
                self.frameInfoList.deallocate()
                self.frameInfoList = nil
            }
            
            if  parser.codecParserContext.pointee.max_frame_num_plus1 > 0 {
                self.frameInfoListCount = Int(parser.codecParserContext.pointee.max_frame_num_plus1)
                self.frameInfoList = UnsafeMutableBufferPointer<VideoFrame.H264>.allocate(capacity: MemoryLayout<VideoFrame.H264>.stride * self.frameInfoListCount)
                memset(self.frameInfoList.baseAddress!, 0, self.frameInfoList.count)
            }
        }
    }
    
    public func parser(_ parser: H264Parser, didParseFrame frame: VideoFrame.H264) {
        self.decode(frame) { (gotPicture) in
            if gotPicture {
                let w = Int(self.pFrame.pointee.width)
                let h = Int(self.pFrame.pointee.height)
                let s = Int(self.pFrame.pointee.pkt_size)
                
                let mes = """
                Frame got:
                w = \(String(w))
                h = \(String(h))
                s = \(String(s))
                """
                print(mes)
            }
            
            
        }
    }
    
}
