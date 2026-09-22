import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let shortcutManager = GlobalShortcutManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "viewfinder", accessibilityDescription: "SnipMac")
            button.image?.isTemplate = true
        }
        statusItem.menu = AppMenu(title: "SnipMac")
        self.statusItem = statusItem

        shortcutManager.onAction = { [weak self] action in
            self?.perform(action)
        }
        shortcutManager.registerDefaults()
    }

    func applicationWillTerminate(_ notification: Notification) {
        shortcutManager.unregisterAll()
    }

    private func perform(_ action: GlobalShortcutManager.Action) {
        switch action {
        case .displayScreenshot:
            ScreenCaptureManager.shared.captureDisplay()
        case .regionScreenshot:
            OverlayWindowManager.shared.showRegionSelector(for: .screenshot)
        case .windowScreenshot:
            OverlayWindowManager.shared.showWindowSelector()
        case .displayRecording:
            ScreenRecorder.shared.startRecordingDisplayUnderPointer()
        case .regionRecording:
            OverlayWindowManager.shared.showRegionSelector(for: .screenRecording)
        }
    }
}
