//
//  AppDelegate.swift
//  SnipMac
//
//  Created by Sai Sandeep Vaddi on 11/19/23.
//

import AppKit
import Cocoa
import Foundation
import SwiftUI

class MenubarPopover: NSPopover {
    override func cancelOperation(_ sender: Any?) {
        performClose(sender)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var eventMonitor: Any?

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(closePopover), name: .closePopover, object: nil)
    }

    @MainActor func applicationDidFinishLaunching(_ notification: Notification) {
        OverlayWindowManager.shared.mainWindow = NSApplication.shared.windows.first
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let statusButton = statusItem?.button {
            statusButton.image = NSImage(systemSymbolName: "u.square.fill", accessibilityDescription: "SnipMac")
            statusButton.action = #selector(togglePopover)
        }

        let popover = MenubarPopover()
        popover.contentSize = NSSize(width: 300, height: 600)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView())
        self.popover = popover
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let popover = self?.popover, popover.isShown {
                self?.closePopover()
            }
        }
    }

    deinit {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }

    @objc func togglePopover() {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }

    @objc func closePopover() {
        popover?.performClose(nil)
    }
}

extension Notification.Name {
    static let closePopover = Notification.Name("ClosePopoverNotification")
}
