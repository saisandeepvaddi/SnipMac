//
//  AppDelegate.swift
//  SnipMac
//
//  Created by Sai Sandeep Vaddi on 11/10/23.
//

import AppKit
import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?
    var overlayWindow: NSWindow?

    override init() {
        super.init()
        AppDelegate.shared = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("AppDelegate is initialized.")
    }

    func showOverlayWindow() {
        if overlayWindow == nil {
            createOverlayWindow()
        }
        overlayWindow?.makeKeyAndOrderFront(nil)
    }

    func hideOverlayWindow() {
        overlayWindow?.orderOut(nil)
    }

    private func createOverlayWindow() {
        let screenRect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 0, height: 0)
        overlayWindow = NSWindow(
            contentRect: screenRect,
            styleMask: [.borderless],
            backing: .buffered, defer: false)
        overlayWindow?.isOpaque = false
        overlayWindow?.backgroundColor = NSColor.clear
        overlayWindow?.level = .screenSaver
        overlayWindow?.ignoresMouseEvents = false

        let contentView = OverlayView()
        overlayWindow?.contentView = NSHostingView(rootView: contentView)
    }
}
