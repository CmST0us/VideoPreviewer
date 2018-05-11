//
//  VideoFrame.swift
//  VideoPreviewer
//
//  Created by CmST0us on 2018/5/11.
//  Copyright © 2018年 eric3u. All rights reserved.
//

import Foundation

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
    
    public enum TypeTag {
        
        public enum VideoFrame: UInt8 {
            case h264Raw = 0
            case jpeg = 2
        }
        
        public enum AudioFrame: UInt8 {
            case aacRaw = 1
        }
        
    }
    
    public struct BasicInfo {
        public struct H264 {
            
            //https://developer.apple.com/library/content/documentation/Swift/Conceptual/BuildingCocoaApps/InteractingWithCAPIs.html#//apple_ref/doc/uid/TP40014216-CH8-ID17
            // [TODO] Union 的导入注意一下
            public struct FrameFlag: OptionSet {
                public var rawValue: UInt32
                
                public init(rawValue: UInt32) {
                    self.rawValue = rawValue
                }
                
                static let SPS = FrameFlag(rawValue: 1 << 32)
                static let PPS = FrameFlag(rawValue: 1 << 31)
                static let IDR = FrameFlag(rawValue: 1 << 30)
                static let fullRange = FrameFlag(rawValue: 1 << 29)
                static let ignoreRender = FrameFlag(rawValue: 1 << 28)
                static let incomplete = FrameFlag(rawValue: 1 << 27)
                
                var SPS: Bool {
                    return FrameFlag.SPS.rawValue & self.rawValue > 0
                }
                
                var PPS: Bool {
                    return FrameFlag.PPS.rawValue & self.rawValue > 0
                }
                
                var IDR: Bool {
                    return FrameFlag.IDR.rawValue & self.rawValue > 0
                }
                
                // [TODO]
            }
            
            var width: UInt16
            var height: UInt16
            
            var fps: UInt16
            var rotate: RotationType
            var reserved: UInt8
            
            var frameIndex: UInt16
            var maxFrameIndexPlusOne: UInt16
            
            var frameFlag: FrameFlag
            var mediaMsTime: UInt32
        }
        
        public struct AAC {
            
        }
    }
    
    public struct H264 {
        var typeTag: TypeTag
        var frameSize: UInt32
        var frameUUID: UInt32
        var timeTag: UInt64
        var basicInfo: BasicInfo.H264
        var frameData: UnsafeRawPointer?
    }

}
