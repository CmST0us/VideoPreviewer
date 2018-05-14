//
//  Utils.swift
//  ViewPreviewer
//
//  Created by CmST0us on 2018/5/10.
//  Copyright © 2018年 eric3u. All rights reserved.
//

import Foundation
import ffmpeg

#if DEBUG
func dumpBitmap(toPath path: String, width: Int, height: Int, linesize: Int, index: Int, data: UnsafeMutablePointer<UInt8>) {
    let filename = "\(path)/dump-\(String(index))"
    let f = fopen(filename, "w")
    let arg: [CVarArg] = [width, height, 255]
    
    withVaList(arg, { (ptr) in
        vfprintf(f, "P5\n%d %d\n%d\n", ptr)
        for i in 0 ..< height {
            fwrite(data.advanced(by: i * linesize), 1, width, f)
        }
    })
    
    fclose(f)
}

#endif

public func VideoPreviewerRegisterFfmpegAll() {
    av_register_all()
}
