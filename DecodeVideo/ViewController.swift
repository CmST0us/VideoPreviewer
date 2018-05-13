//
//  ViewController.swift
//  DecodeVideo
//
//  Created by CmST0us on 2018/5/14.
//  Copyright © 2018年 eric3u. All rights reserved.
//

import UIKit
import VideoPreviewer

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    var decoder: H264SoftwareDecoder!
    var fps: Int = 0
    var frameCount: Int = 0
    var fpsTimer: Timer!
    var timerThread: Thread!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        decoder = H264SoftwareDecoder()
        decoder.initial()
        decoder.delegate = self
        decoder.open()
        self.timerThread = Thread.init(block: { [weak self] in
            
            self!.fpsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer) in
                self!.fps = self!.frameCount
                self!.frameCount = 0
            })
            
            while !Thread.current.isCancelled {
                RunLoop.current.run(until: Date.init(timeIntervalSinceNow: 2.0))
            }
            
        })
        
        self.timerThread.start()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        Thread.detachNewThread {
            let data = NSData.init(contentsOfFile: "/Users/cmst0us/Desktop/swift.h264")!
            let mutablePtr = UnsafeMutableRawBufferPointer.init(start: UnsafeMutableRawPointer(mutating: data.bytes), count: data.length)
            var uselen: Int = 0
            self.decoder.parser.parse(mutablePtr, usedLength: &uselen)
        }
    }

}

extension ViewController: H264SoftwareDecoderDelegate {
    func decoder(_ decoder: H264SoftwareDecoder, didGotPicture picture: VideoFrame.YUV) {
        let w = Int(picture.width)
        let h = Int(picture.height)
        let s = Int(picture.frameInfo.frameIndex)
        self.frameCount += 1
        let mes = """
        fps (\(String(self.fps))) Frame got:
        w = \(String(w))
        h = \(String(h))
        s = \(String(s))
        """
        print(mes)
        if let cgImageUnmanaged = picture.getYUV420PCVImage() {
            let cgImage = cgImageUnmanaged.takeRetainedValue()
            let image = UIImage.init(cgImage: cgImage)
            
            DispatchQueue.main.async {
                self.imageView.image = image
            }
        }
        
    }
}
