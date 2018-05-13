//
//  H264SoftwareDecoder.swift
//  VideoPreviewer
//
//  Created by CmST0us on 2018/5/12.
//  Copyright © 2018年 eric3u. All rights reserved.
//

import Foundation
import ffmpeg

public protocol H264SoftwareDecoderDelegate {
    func decoder(_ decoder: H264SoftwareDecoder, didGotPicture picture: VideoFrame.YUV)
}

/// 使用ffmpeg的H264解码器
open class H264SoftwareDecoder {
    
    // MARK: - Public Member
    /// h264解析器
    public var parser: H264Parser!
    
    /// 解码器Delegate
    public var delegate: H264SoftwareDecoderDelegate?
    
    // MARK: - Private Member
    public typealias AVFramePtr = UnsafeMutablePointer<AVFrame>

    private var pFrame: AVFramePtr!
    private var frameInfoListCount: Int!
    private var frameInfoList: UnsafeMutableBufferPointer<VideoFrame.H264>!
    
    private let renderFrameBufferSize: Int
    private var renderFrameBuffer: UnsafeMutableBufferPointer<VideoFrame.YUV>!
    
    // MARK: - Internal Member
    public init(renderFrameBufferSize: Int) {
        self.renderFrameBufferSize = renderFrameBufferSize
        self.initial()
    }
    
    convenience public init() {
        self.init(renderFrameBufferSize: 2)
        
    }
    deinit {
        self.close()
        self.free()
    }
    
}

// MARK: - Public Method
extension H264SoftwareDecoder {
    public func initial() {
        
        // 初始化解析器
        self.parser = H264Parser()
        self.parser.delegate = self
        self.parser.initial()
        
        self.pFrame = av_frame_alloc()

        // [TODO] [WARNING] 探究一下这个标记
        self.parser.codecContext.pointee.flags2 |= CODEC_FLAG2_FAST
        // decide how many independent tasks should be passed to execute()
        self.parser.codecContext.pointee.thread_count = 2
        self.parser.codecContext.pointee.thread_type = FF_THREAD_FRAME
        
        if (self.parser.codec.pointee.capabilities & CODEC_FLAG_LOW_DELAY) > 0 {
            self.parser.codecContext.pointee.flags |= CODEC_FLAG_LOW_DELAY
        }
        
        self.frameInfoListCount = 0
        self.frameInfoList = nil
        
        self.renderFrameBuffer = UnsafeMutableBufferPointer<VideoFrame.YUV>.allocate(capacity: self.renderFrameBufferSize * MemoryLayout<VideoFrame.YUV>.stride)
        let defaultYUV = VideoFrame.YUV()
        self.renderFrameBuffer.initialize(repeating: defaultYUV)
        
    }
    
    public func free() {
        objc_sync_enter(self)
        
        if self.pFrame != nil {
            av_freep(&self.pFrame)
        }
        
        self.parser.free()
        
        if self.frameInfoList != nil {
            self.frameInfoList.deallocate()
            self.frameInfoList = nil
            self.frameInfoListCount = 0
        }
        
        if self.renderFrameBuffer != nil {
            for i in 0 ..< self.renderFrameBufferSize {
                self.renderFrameBuffer[i].free()
            }
            self.renderFrameBuffer.deallocate()
            self.renderFrameBuffer = nil
        }
        objc_sync_exit(self)
    }
    
    public func open() -> Bool{
        var nullPtr: OpaquePointer? = nil
        return avcodec_open2(self.parser.codecContext, self.parser.codec, &nullPtr) == 0
    }
    
    public func close() {
        avcodec_close(self.parser.codecContext)
    }
    
    public func decode(_ frame: VideoFrame.H264, block: (_ didGotPicture: Bool) -> Void) {
        objc_sync_enter(self)
        
        if frame.frameData == nil || frame.frameSize <= 0{
            block(false)
            objc_sync_exit(self)
            return
        }
        
        var packet = AVPacket()
        av_init_packet(&packet)
        packet.data = frame.frameData
        packet.size = Int32(frame.frameSize)
        
        while packet.size > 0 {
            if self.frameInfoListCount > frame.frameInfo.frameIndex {
                let currentFrameIndex = Int(frame.frameInfo.frameIndex)
                self.frameInfoList[currentFrameIndex] = frame
            }
            
            var didGotPicture: Int32 = 0
            
            let decodeLen = avcodec_decode_video2(self.parser.codecContext, self.pFrame, &didGotPicture, &packet)
            
            
            if self.parser.codecContext.pointee.height == 1088 {
                self.parser.codecContext.pointee.height = 1080
            }
            
            block(didGotPicture > 0)
            
            if decodeLen < 0 {
                break
            }
            
            packet.size -= decodeLen
        }
        
        av_free_packet(&packet)
        
        objc_sync_exit(self)
    }
}

// MARK: - Private Method
extension H264SoftwareDecoder {
    private func getYUV420P(from frame: AVFramePtr, to yuvFrame: inout VideoFrame.YUV) {
        objc_sync_enter(self)
        
        // 检查色彩空间
        if frame.pointee.format != AV_PIX_FMT_YUV420P.rawValue {
            return
        }
        
        let inputWidth = Int(frame.pointee.width)
        let inputHeigth = Int(frame.pointee.height)
        
        if yuvFrame.luma != nil &&
            (yuvFrame.width != frame.pointee.width || yuvFrame.height != frame.pointee.height) {
            yuvFrame.luma.deallocate()
            yuvFrame.chromaB.deallocate()
            yuvFrame.chromaR.deallocate()
            
            yuvFrame.luma = nil
            yuvFrame.chromaB = nil
            yuvFrame.chromaR = nil
        }
        
        if yuvFrame.luma == nil {
            yuvFrame.luma = UnsafeMutablePointer<UInt8>.allocate(capacity: inputWidth * inputWidth)
            yuvFrame.chromaB = UnsafeMutablePointer<UInt8>.allocate(capacity: inputWidth * inputWidth / 4)
            yuvFrame.chromaR = UnsafeMutablePointer<UInt8>.allocate(capacity: inputWidth * inputWidth / 4)
        }
        copyYUVFrame(dst: yuvFrame.luma,
                     src: self.pFrame.pointee.data.0!,
                     linesize: Int(frame.pointee.linesize.0),
                     width: inputWidth, height: inputHeigth)
        
        // UV分量交叉放置
        // https://www.cnblogs.com/samaritan/p/YUV.html
        copyYUVFrame(dst: yuvFrame.chromaB,
                     src: self.pFrame.pointee.data.1!,
                     linesize: Int(frame.pointee.linesize.1),
                     width: inputWidth / 2, height: inputHeigth / 2)
        
        copyYUVFrame(dst: yuvFrame.chromaR,
                     src: self.pFrame.pointee.data.2!,
                     linesize: Int(frame.pointee.linesize.2),
                     width: inputWidth / 2, height: inputHeigth / 2)
        
        yuvFrame.lumaLineSize = Int(frame.pointee.linesize.0)
        yuvFrame.chromaBLineSize = Int(frame.pointee.linesize.1)
        yuvFrame.chromaRLineSize = Int(frame.pointee.linesize.2)
        
        yuvFrame.width = inputWidth
        yuvFrame.height = inputHeigth
        yuvFrame.frameUUID = H264_FRAME_INVAILED_UUID
        
        // [TODO] 这个poc是什么
        if frame.pointee.poc < self.frameInfoListCount {
            let poc = Int(frame.pointee.poc)
            yuvFrame.frameUUID = frameInfoList[poc].frameUUID
            yuvFrame.frameInfo = frameInfoList[poc].frameInfo
        }
        
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
        var bufferIndex = 0
        self.decode(frame) { (gotPicture) in
            if gotPicture {
                // 需要判断帧的色彩空间
                // 向外抛出的所有手动管理内存的结构体，都应放入队列中统一处理, 测试通过后，使用队列处理
                // 注意这个对象内部有手动管理的内存
                // [TODO] 看看&符号会不会发生拷贝
                if self.pFrame.pointee.format == AV_PIX_FMT_YUV420P.rawValue {
                    self.getYUV420P(from: self.pFrame, to: &self.renderFrameBuffer[bufferIndex])
                    if self.delegate != nil {
                        self.delegate?.decoder(self, didGotPicture: self.renderFrameBuffer[bufferIndex])
                    }
                    bufferIndex = (bufferIndex + 1) % self.renderFrameBufferSize
                }
            }
        }
        
    }
    
}
