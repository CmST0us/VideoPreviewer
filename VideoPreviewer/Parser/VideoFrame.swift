//
//  VideoFrame.swift
//  VideoPreviewer
//
//  Created by CmST0us on 2018/5/11.
//  Copyright © 2018年 eric3u. All rights reserved.
//

import Foundation
import Accelerate

#if os(iOS)
import CoreVideo
#endif

public let AV_NOPTS_VALUE = 0x8000_0000_0000_0000 as UInt64
public let H264_FRAME_INVAILED_UUID: UInt32 = 0

func copyYUVFrame(dst: UnsafeMutablePointer<UInt8>,
                  src: UnsafePointer<UInt8>,
                  linesize: Int,
                  width: Int,
                  height: Int) {
    
    guard linesize >= width && width > 0 else {
        return
    }
    
    var dstPtr = dst
    var srcPtr = UnsafeMutablePointer<UInt8>.init(mutating: src)
    let ls = linesize
    let w = width
    let h = height
    
    for _ in 0 ..< h {
        dstPtr.assign(from: src, count: width)
        dstPtr = dstPtr.advanced(by: w)
        srcPtr = srcPtr.advanced(by: ls)
    }
    
}

public struct VideoFrame {
    
    /// The live stream is rotated 90 degrees cw. VideoPreviewer will rotate 90 degrees ccw when render it to screen.
    ///
    /// - `default`: 0
    /// - cw90: cw 90
    /// - cw180: cw 180
    /// - cw270: cw 270
    public enum RotationType {
        case `default`
        case cw90
        case cw180
        case cw270
    }
    
    public enum TypeTag: UInt8 {
        
        case videoFrameH264Raw = 0
        case audioFrameAACRaw = 1
        case videoFrameJPEG = 2
        
    }
    
    public enum FrameType: UInt8 {
        case yuv420Planer = 0
        case yuv420SemiPlaner = 1
        case rgba = 2
    }
    
    public struct BasicInfo {
        public struct H264 {
            
            //https://developer.apple.com/library/content/documentation/Swift/Conceptual/BuildingCocoaApps/InteractingWithCAPIs.html#//apple_ref/doc/uid/TP40014216-CH8-ID17
            // [TODO] Union 的导入注意一下
            public struct FrameFlag {
                public var hasSPS: Bool = false
                public var hasPPS: Bool = false
                public var hasIDR: Bool = false
                public var isFullRange: Bool = false
                public var ignoreRender: Bool = true
                public var incompleteFrameFlag: Bool = true
                public var reserved: Int32 = 0
                
//                channelType
            }
            
            public var width: Int32 = 0
            public var height: Int32 = 0
            
            public var fps: UInt16 = 0
            public var rotate: RotationType = .default
            public var reserved: UInt8 = 0
            
            public var frameIndex: Int32 = 0
            public var maxFrameIndexPlusOne: Int32 = 0
            
            public var frameFlag: FrameFlag = FrameFlag()
            public var framePoc: Int32 = 0
            public var mediaMsTime: UInt32 = 0
        }
        
        public struct AAC {
            
        }
    }
    
    public struct H264 {
        public var typeTag: TypeTag = .videoFrameH264Raw
        public var frameSize: UInt32 = 0
        public var frameUUID: UInt32 = 0
        public var timeTag: UInt64 = 0
        public var frameInfo: BasicInfo.H264 = BasicInfo.H264()
        public var frameData: UnsafeMutablePointer<UInt8>?
    }
    
    public struct YUV {
        public var luma: UnsafeMutablePointer<UInt8>!
        public var chromaB: UnsafeMutablePointer<UInt8>!
        public var chromaR: UnsafeMutablePointer<UInt8>!
        
        public var frameType: FrameType = .yuv420Planer
        public var width: Int = 0
        public var height: Int = 0
        
        public var lumaLineSize: Int = 0
        public var chromaBLineSize: Int = 0
        public var chromaRLineSize: Int = 0
        
//      var mutex  自旋锁？？？
        public var cvPixelBufferFastUpload: UnsafeMutableRawPointer!
        
        public var frameUUID: UInt32 = 0
        public var frameInfo = BasicInfo.H264()
        
        mutating func free() {
            if self.luma != nil {
                self.luma.deallocate()
                self.luma = nil
            }
            
            if self.chromaB != nil {
                self.chromaB.deallocate()
                self.chromaB = nil
            }
            
            if self.chromaR != nil {
                self.chromaR.deallocate()
                self.chromaR = nil
            }
            
        }
        
        public func getYUV420PCVImage() -> CVImageBuffer? {
            let options = [
                kCVPixelBufferCGImageCompatibilityKey: NSNumber.init(value: true),
                kCVPixelBufferCGBitmapContextCompatibilityKey: NSNumber.init(value: true),
            ]
            
            var pixBuffer: CVPixelBuffer? = nil
            let ret = CVPixelBufferCreate(kCFAllocatorDefault, self.width, self.height, kCVPixelFormatType_420YpCbCr8Planar, options as CFDictionary, &pixBuffer)
            
            if ret != kCVReturnSuccess {
                return nil
            }
            
            if CVPixelBufferLockBaseAddress(pixBuffer!, CVPixelBufferLockFlags.init(rawValue: 0)) != kCVReturnSuccess {
                return nil
            }
            
            let luma = CVPixelBufferGetBaseAddressOfPlane(pixBuffer!, 0)!.bindMemory(to: UInt8.self, capacity: self.width * self.height)
            let chromaB = CVPixelBufferGetBaseAddressOfPlane(pixBuffer!, 1)!.bindMemory(to: UInt8.self, capacity: self.width * self.height / 4)
            let chromaR = CVPixelBufferGetBaseAddressOfPlane(pixBuffer!, 2)!.bindMemory(to: UInt8.self, capacity: self.width * self.height / 4)
            
            copyYUVFrame(dst: luma, src: self.luma, linesize: self.lumaLineSize, width: self.width, height: self.height)
            copyYUVFrame(dst: chromaB, src: self.chromaB, linesize: self.chromaBLineSize, width: self.width, height: self.height)
            copyYUVFrame(dst: chromaR, src: self.chromaR, linesize: self.chromaRLineSize, width: self.width, height: self.height)
            
            CVPixelBufferUnlockBaseAddress(pixBuffer!, CVPixelBufferLockFlags.init(rawValue: 0))
            
            return pixBuffer
        }
        
    }

}
