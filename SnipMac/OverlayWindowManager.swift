//
//  OverlayWindowManager.swift
//  SnipMac
//
//  Created by Sai Sandeep Vaddi on 11/18/23.
//
import AppKit
import SwiftUI

class OverlayWindowManager {
    static let shared = OverlayWindowManager()
    var overlayWindow: NSWindow?
    var mainWindow: NSWindow?
    private var appState: AppState?

    // Accept AppState as a parameter
    func setAppState(_ appState: AppState) {
        self.appState = appState
        observeAppStateChanges()
    }

    private func observeAppStateChanges() {}

    func showOverlayWindow(captureType: CaptureType) {
        if overlayWindow == nil {
            createOverlayWindow(captureType: captureType)
        }
        overlayWindow?.makeKeyAndOrderFront(nil)
    }

    func hideOverlayWindow() {
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
    }

    func hideMainWindow() {
        mainWindow?.orderOut(nil)
    }

    func showMainWindow() {
        mainWindow?.makeKeyAndOrderFront(nil)
    }

    private func createOverlayWindow(captureType: CaptureType) {
        let screenRect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 0, height: 0)
        overlayWindow = NSWindow(
            contentRect: screenRect,
            styleMask: [.borderless],
            backing: .buffered, defer: false)
        overlayWindow?.isOpaque = false
        overlayWindow?.backgroundColor = NSColor.clear
        overlayWindow?.level = .screenSaver
        overlayWindow?.ignoresMouseEvents = false
        print("Creating new overlay")
        let contentView = ScreenshotOverlayView(captureType: captureType)
        overlayWindow?.contentView = NSHostingView(rootView: contentView)
    }
}
