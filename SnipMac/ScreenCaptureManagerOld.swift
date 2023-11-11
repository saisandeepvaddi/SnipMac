//
//  ScreenCaptureManager.swift
//  SnipMac
//
//  Created by Sai Sandeep Vaddi on 11/6/23.
//

import AppKit
import AVFoundation
import Foundation

class ScreenCaptureManagerOld {
    var permissionGranted = false

    func captureScreen() -> NSImage? {
        let semaphore = DispatchSemaphore(value: 0)
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            permissionGranted = true
            semaphore.signal()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                print("granted: \(granted)")
                self.permissionGranted = granted
                semaphore.signal()
            }
        case .denied:
            permissionGranted = false
            semaphore.signal()
        default:
            print("Screen Recording permission is not granted.")
            permissionGranted = false
            semaphore.signal()
        }
        semaphore.wait()
        if permissionGranted {
            return performScreenCapture()
        }
        return nil
    }

    private func performScreenCapture() -> NSImage? {
        guard let screen = NSScreen.main else { return nil }
        let screenRect = screen.frame
        let windowID = CGWindowID(0)
        let imageRef = CGWindowListCreateImage(screenRect, .optionIncludingWindow, windowID, .bestResolution)
        print(imageRef)
        if let imgRef = imageRef {
            return NSImage(cgImage: imgRef, size: screenRect.size)
        } else {
            return nil
        }
    }

    func saveImage(_ image: NSImage, toPath path: String, ofType type: NSBitmapImageRep.FileType) {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else { return }

        let imageData = bitmapRep.representation(using: type, properties: [:])
        try? imageData?.write(to: URL(fileURLWithPath: path))
    }
}
