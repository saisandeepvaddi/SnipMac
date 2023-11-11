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
    static func takeScreenshot() {
        checkScreenCapturePermission {
            let displayID = CGMainDisplayID()
            let screenFrame = CGDisplayBounds(displayID)

            guard let imageRef = CGWindowListCreateImage(screenFrame, .optionOnScreenOnly, kCGNullWindowID, .bestResolution) else {
                print("Unable to capture the screen")
                return
            }

            let bitmapRep = NSBitmapImageRep(cgImage: imageRef)

            guard let data = bitmapRep.representation(using: .png, properties: [:]) else {
                print("Failed to convert the image to PNG format")
                return
            }

            saveScreenShot(data: data)
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

    static func saveScreenShot(data: Data) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.png, UTType.jpeg, UTType.webP]
        savePanel.nameFieldStringValue = "SnipMacScreenShot.png"
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
}
