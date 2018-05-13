//
//  VideoFrame.swift
//  VideoPreviewer
//
//  Created by CmST0us on 2018/5/11.
//  Copyright © 2018年 eric3u. All rights reserved.
//

import Foundation

#if os(iOS)
import Accelerate
import CoreGraphics
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
        
        public func getYUV420PCVImage() -> Unmanaged<CGImage>? {
            
            var lumaBuffer = vImage_Buffer()
            var chromaBBuffer = vImage_Buffer()
            var chromaRBuffer = vImage_Buffer()
            var destBuffer = vImage_Buffer()
            
            vImageBuffer_Init(&lumaBuffer, UInt(self.height), UInt(self.width), 8, UInt32(kvImageNoFlags))
            
            vImageBuffer_Init(&chromaBBuffer, UInt(self.height), UInt(self.width), 8, UInt32(kvImageNoFlags))

            vImageBuffer_Init(&chromaRBuffer, UInt(self.height), UInt(self.width), 8, UInt32(kvImageNoFlags))
            
            vImageBuffer_Init(&destBuffer, UInt(self.height), UInt(self.width), 8, UInt32(kvImageNoFlags))
            
            vImageBufferFill_CbCr8(&lumaBuffer, self.luma, UInt32(kvImageNoFlags))
            vImageBufferFill_CbCr8(&chromaBBuffer, self.chromaB, UInt32(kvImageNoFlags))
            vImageBufferFill_CbCr8(&chromaRBuffer, self.chromaR, UInt32(kvImageNoFlags))
            
            var convertInfo = vImage_YpCbCrToARGB.init()
            var pixelRange = vImage_YpCbCrPixelRange(Yp_bias: 16, CbCr_bias: 128, YpRangeMax: 235, CbCrRangeMax: 240, YpMax: 255, YpMin: 0, CbCrMax: 255, CbCrMin: 0)
            
            var permuteMap: [UInt8] = [0, 1, 2, 3] // ARGB
            // [TODO] 看看frame里面的标准是什么
            vImageConvert_YpCbCrToARGB_GenerateConversion(kvImage_YpCbCrToARGBMatrix_ITU_R_601_4, &pixelRange, &convertInfo, kvImage420Yp8_Cb8_Cr8, kvImageARGB8888, vImage_Flags(kvImageNoFlags))
            
            if vImageConvert_420Yp8_Cb8_Cr8ToARGB8888(&lumaBuffer, &chromaBBuffer, &chromaRBuffer, &destBuffer, &convertInfo, &permuteMap, 255, vImage_Flags(kvImageNoFlags)) != kvImageNoError {
                lumaBuffer.data.deallocate()
                chromaBBuffer.data.deallocate()
                chromaRBuffer.data.deallocate()
                destBuffer.data.deallocate()
                return nil
            }
            
            var format = vImage_CGImageFormat()
            let bitmapInfo = CGImageAlphaInfo.first.rawValue | CGImageByteOrderInfo.orderDefault.rawValue
            format.bitmapInfo = CGBitmapInfo.init(rawValue: bitmapInfo)
            format.bitsPerComponent = 8
            format.bitsPerPixel = 32
            format.colorSpace = Unmanaged<CGColorSpace>.passRetained(CGColorSpaceCreateDeviceRGB())
            format.decode = nil
            format.renderingIntent = .defaultIntent
            format.version = 0
            
            var error: vImage_Error = 0
            let ret = vImageCreateCGImageFromBuffer(&destBuffer,
                                          &format, { (ptr1, ptr2) in
                
            }, nil, vImage_Flags(kvImageNoFlags), &error)
            
            lumaBuffer.data.deallocate()
            chromaBBuffer.data.deallocate()
            chromaRBuffer.data.deallocate()
            destBuffer.data.deallocate()
            
            return ret
        }
        
    }

}
