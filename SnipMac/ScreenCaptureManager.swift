//
//  ScreenCaptureManager.swift
//  SnipMac
//
//  Created by Sai Sandeep Vaddi on 11/10/23.
//

import AppKit
import Foundation
import UniformTypeIdentifiers

class ScreenCaptureManager {
    static func takeScreenshot(of area: CGRect? = nil) {
        checkScreenCapturePermission {
            let captureRect = area ?? CGDisplayBounds(CGMainDisplayID())

            guard let imageRef = CGWindowListCreateImage(captureRect, .optionOnScreenOnly, kCGNullWindowID, .bestResolution) else {
                print("Unable to capture the screen")
                return
            }

            let bitmapRep = NSBitmapImageRep(cgImage: imageRef)

            guard let data = bitmapRep.representation(using: .png, properties: [:]) else {
                print("Failed to convert the image to PNG format")
                return
            }

            saveScreenshot(data: data)
        }
    }

    private static func checkScreenCapturePermission(completion: @escaping () -> Void) {
        let displayID = CGMainDisplayID()
        let screenFrame = CGDisplayBounds(displayID)
        let dummyImage = CGWindowListCreateImage(screenFrame, .optionOnScreenOnly, kCGNullWindowID, .bestResolution)

        if dummyImage != nil {
            completion()
        } else {
            print("Screen capture permission not granted.")
        }
    }

    static func saveScreenShotWithSavePanel(data: Data) {
        let savePanel = NSSavePanel()

        savePanel.allowedContentTypes = [UTType.png, UTType.jpeg, UTType.webP]

        let dateStr = Date().formatted(date: .abbreviated, time: .standard)
        savePanel.nameFieldStringValue = "SnipMacScreenShot \(dateStr).png"
        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                do {
                    try data.write(to: url)
                    print("Screenshot saved to: \(url)")
                } catch {
                    print("Failed to save screenshot: \(error)")
                }
            }
        }
    }

    static func saveScreenshot(data: Data) {
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!

        let dateStr = Date().formatted(date: .abbreviated, time: .standard).utf8
        let filename = "SnipMacScreenShot \(dateStr).png"

        let fileURL = desktopURL.appendingPathComponent(filename)
        do {
            try data.write(to: fileURL, options: .atomic)
            print("Screenshot saved to: \(fileURL.path())")
        } catch {
            print("Failed to save screenshot: \(error)")
        }
    }

    static func listWindows() {}

    static func captureWindow(windowID: CGWindowID) {}
}
