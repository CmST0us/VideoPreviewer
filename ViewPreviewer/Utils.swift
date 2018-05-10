//
//  Utils.swift
//  ViewPreviewer
//
//  Created by CmST0us on 2018/5/10.
//  Copyright © 2018年 eric3u. All rights reserved.
//

import Foundation

private func synchronized(_ o: Any, _ block: (() -> Void)) {
    objc_sync_enter(o)
    block()
    objc_sync_exit(o)
}
