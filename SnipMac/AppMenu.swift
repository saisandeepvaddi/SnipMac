//
//  AppMenu.swift
//  SnipMac
//
//  Created by Sai Sandeep Vaddi on 2/4/24.
//

import Cocoa

class AppMenu: NSMenu {
    let screenRecorder = ScreenRecorder.shared
    let overlayWindowManager = OverlayWindowManager.shared

    override init(title: String) {
        super.init(title: title)
        self.addMenuItems()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func addMenuItems() {
        self.addStyledMenuItem(title: "Take Screenshot", action: #selector(self.takeScreenshot), keyEquivalent: "", systemIconName: "rectangle.dashed")

        self.addStyledMenuItem(title: "Capture Area", action: #selector(self.captureArea), keyEquivalent: "", systemIconName: "rectangle.inset.filled")

        self.addItem(NSMenuItem.separator())

        self.addStyledMenuItem(title: "Start Recording whole screen", action: #selector(self.startRecordingWholeScreen), keyEquivalent: "", systemIconName: "record.circle")

        self.addStyledMenuItem(title: "Start Recording area", action: #selector(self.startRecordingArea), keyEquivalent: "", systemIconName: "rectangle.dashed.badge.record")

        self.addStyledMenuItem(title: "Stop Recording", action: #selector(self.stopRecording), keyEquivalent: "", systemIconName: "stop.circle")

        self.addItem(NSMenuItem.separator())

        self.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc func takeScreenshot() {
        withMenubarClosed {
            ScreenCaptureManager.takeScreenshot()
        }
    }

    @objc func captureArea() {
        withMenubarClosed {
            self.overlayWindowManager.showOverlayWindow(captureType: .screenshot)
        }
    }

    @objc func startRecordingWholeScreen() {
        withMenubarClosed {
            self.screenRecorder.startRecordingMainScreen()
        }
    }

    @objc func startRecordingArea() {
        withMenubarClosed {
            self.overlayWindowManager.showOverlayWindow(captureType: .screenRecord)
        }
    }

    @objc func stopRecording() {
        withMenubarClosed {
            self.screenRecorder.stopRecording()
        }
    }
}

extension AppMenu {
    func menuItem(title: String, action: Selector?, keyEquivalent: String) -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        menuItem.target = self
        return menuItem
    }
}

extension NSMenu {
    func addStyledMenuItem(title: String, action: Selector?, keyEquivalent: String, systemIconName: String? = nil) {
        let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        menuItem.target = self

        if let systemIconName = systemIconName {
            if #available(macOS 11.0, *) {
                let config = NSImage.SymbolConfiguration(scale: .large) // You can choose .default, .small, .medium, or .large
                menuItem.image = NSImage(systemSymbolName: systemIconName, accessibilityDescription: nil)?.withSymbolConfiguration(config)
                menuItem.image?.isTemplate = true // Ensure the icon adapts to light/dark mode
            } else {
                // Fallback on earlier versions or handle the error
            }
        }

        // Add more styling if needed

        self.addItem(menuItem)
    }
}
