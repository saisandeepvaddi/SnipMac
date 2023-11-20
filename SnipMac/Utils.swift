//
//  Utils.swift
//  SnipMac
//
//  Created by Sai Sandeep Vaddi on 11/11/23.
//

import AppKit
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

func scaleRect(input: CGRect) -> CGRect {
    let screen = NSScreen.main
    guard let screen = screen else {
        return input
    }
    let scaleFactor = 2.0
    let scaledRect = CGRect(
        x: input.minX * scaleFactor,
        y: input.minY * scaleFactor,
        width: input.width * scaleFactor,
        height: input.height * scaleFactor
    )
    return scaledRect
}

func calculateCropRect(from selectedRect: CGRect) -> CGRect {
    guard let screen = NSScreen.main else { return CGRect.zero }
    let scaleFactor = screen.backingScaleFactor

    // Assuming selectedRect is in global screen coordinates
    // Convert to bottom-left origin used by macOS screen coordinates
    let flippedRect = CGRect(x: selectedRect.origin.x,
                             y: screen.frame.height - selectedRect.origin.y - selectedRect.height,
                             width: selectedRect.width,
                             height: selectedRect.height)

    // Apply scale factor for Retina displays
    let scaledRect = CGRect(x: flippedRect.origin.x * scaleFactor,
                            y: flippedRect.origin.y * scaleFactor,
                            width: flippedRect.width * scaleFactor,
                            height: flippedRect.height * scaleFactor)

    return scaledRect
}

enum CaptureType {
    case screenshot
    case screenRecord
}
