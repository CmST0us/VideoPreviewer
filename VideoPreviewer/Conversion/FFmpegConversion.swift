//
//  FFmpegConversion.swift
//  VideoPreviewer
//
//  Created by CmST0us on 2018/5/14.
//  Copyright © 2018年 eric3u. All rights reserved.
//

import Foundation
import ffmpeg

public enum ConversionSupportFormat: Int {
    case yuv420p = 1
    case argb8888 = 2
}

class FFmpegConversion {
    // MARK: - Public Member
    typealias AVFormatContextPtr = UnsafeMutablePointer<AVFormatContext>
    
    var formatContext: AVFormatContextPtr!
    
    var sourcePixelMap: VideoFrame.PixelMap
    var destPixelMap: VideoFrame.PixelMap
    
    var sourceFormat: ConversionSupportFormat
    var destFormat: ConversionSupportFormat
    
    init(sourceWidth: Int, sourceHeight: Int, sourceFormat: ConversionSupportFormat, sourceLineSize: Int, destWidth: Int, destHeight: Int, destFormat: ConversionSupportFormat, destLineSize: Int) {
        self.sourcePixelMap = VideoFrame.PixelMap(width: sourceHeight, height: sourceHeight, lineSize: sourceLineSize)
        self.destPixelMap = VideoFrame.PixelMap(width: destWidth, height: destHeight, lineSize: destLineSize)
        self.sourceFormat = sourceFormat
        self.destFormat = destFormat
        self.initial()
    }
    
    // MARK- Private Member
}

// MARK: - Public Method
extension FFmpegConversion {
    func initial() {
        
    }
}
