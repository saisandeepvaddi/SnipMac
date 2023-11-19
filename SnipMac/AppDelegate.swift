//
//  AppDelegate.swift
//  SnipMac
//
//  Created by Sai Sandeep Vaddi on 11/10/23.
//

import AppKit
import Cocoa
import Combine
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?

    var overlayWindow: NSWindow?
    var mainWindow: NSWindow?

    override init() {
        super.init()
        AppDelegate.shared = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("AppDelegate is initialized.")
    }

    func showOverlayWindow(captureType: CaptureType, screenRecorder: ScreenRecorder? = nil) {
        if overlayWindow == nil {
            createOverlayWindow(captureType: captureType, screenRecorder: screenRecorder)
        }
        overlayWindow?.makeKeyAndOrderFront(nil)
    }

    func hideOverlayWindow() {
        overlayWindow?.orderOut(nil)
    }

    func hideMainWindow() {
        mainWindow?.orderOut(nil)
    }

    func showMainWindow() {
        mainWindow?.makeKeyAndOrderFront(nil)
    }

    private func createOverlayWindow(captureType: CaptureType, screenRecorder: ScreenRecorder? = nil) {
        let screenRect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 0, height: 0)
        overlayWindow = NSWindow(
            contentRect: screenRect,
            styleMask: [.borderless],
            backing: .buffered, defer: false)
        overlayWindow?.isOpaque = false
        overlayWindow?.backgroundColor = NSColor.clear
        overlayWindow?.level = .screenSaver
        overlayWindow?.ignoresMouseEvents = false

        let contentView = ScreenshotOverlayView(captureType: captureType, screenRecorder: screenRecorder ?? ScreenRecorder())
        overlayWindow?.contentView = NSHostingView(rootView: contentView)
    }
}
