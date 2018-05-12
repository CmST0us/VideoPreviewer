//
//  VideoFrame.swift
//  VideoPreviewer
//
//  Created by CmST0us on 2018/5/11.
//  Copyright © 2018年 eric3u. All rights reserved.
//

import Foundation

public let AV_NOPTS_VALUE = 0x8000_0000_0000_0000 as UInt64
public let H264_FRAME_INVAILED_UUID = 0

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
    
    public struct BasicInfo {
        public struct H264 {
            
            //https://developer.apple.com/library/content/documentation/Swift/Conceptual/BuildingCocoaApps/InteractingWithCAPIs.html#//apple_ref/doc/uid/TP40014216-CH8-ID17
            // [TODO] Union 的导入注意一下
            public struct FrameFlag {
                var hasSPS: Bool = false
                var hasPPS: Bool = false
                var hasIDR: Bool = false
                var isFullRange: Bool = false
                var ignoreRender: Bool = true
                var incompleteFrameFlag: Bool = true
                var reserved: Int32 = 0
                
//                channelType
            }
            
            var width: Int32 = 0
            var height: Int32 = 0
            
            var fps: UInt16 = 0
            var rotate: RotationType = .default
            var reserved: UInt8 = 0
            
            var frameIndex: Int32 = 0
            var maxFrameIndexPlusOne: Int32 = 0
            
            var frameFlag: FrameFlag = FrameFlag()
            var framePoc: Int32 = 0
            var mediaMsTime: UInt32 = 0
        }
        
        public struct AAC {
            
        }
    }
    
    public struct H264 {
        var typeTag: TypeTag = .videoFrameH264Raw
        var frameSize: UInt32 = 0
        var frameUUID: UInt32 = 0
        var timeTag: UInt64 = 0
        var frameInfo: BasicInfo.H264 = BasicInfo.H264()
        var frameData: UnsafeMutablePointer<UInt8>?
    }

}
