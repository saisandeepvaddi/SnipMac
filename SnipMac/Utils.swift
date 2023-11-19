//
//  Utils.swift
//  SnipMac
//
//  Created by Sai Sandeep Vaddi on 11/11/23.
//

import Foundation

func withMainWindowClosed(_ action: @escaping () -> Void) {
    let overlayWindowManager = OverlayWindowManager.shared
    overlayWindowManager.hideMainWindow()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        action()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            overlayWindowManager.showMainWindow()
        }
    }
}

enum CaptureType {
    case screenshot
    case screenRecord
}
