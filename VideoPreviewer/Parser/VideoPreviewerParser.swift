//
//  VideoPreviewerParser.swift
//  VideoPreviewer
//
//  Created by CmST0us on 2018/5/11.
//  Copyright © 2018年 eric3u. All rights reserved.
//

import Foundation

public protocol VideoPreviewerParser {
    var frameRate: Int { get }
    var frameInterval: TimeInterval { get }
    var outputWidth: Int { get }
    var outputHeight: Int { get }
    
    var delegate: VideoPreviewerParserDelegate? {get set}
}

public protocol VideoPreviewerParserDelegate {
    func parser(_ parser: VideoPreviewerParser, didParseFrame frame: VideoFrame.H264)
}
