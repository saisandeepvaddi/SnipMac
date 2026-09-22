import AppKit

@MainActor
final class AppMenu: NSMenu {
    private let screenRecorder = ScreenRecorder.shared
    private let overlayWindowManager = OverlayWindowManager.shared

    override init(title: String) {
        super.init(title: title)
        autoenablesItems = false
        rebuild()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recordingStateChanged),
            name: .recordingStateChanged,
            object: nil
        )
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func rebuild() {
        removeAllItems()

        addSectionHeader("Screenshot")
        addAction(
            "Capture Display",
            symbol: "display",
            shortcut: .displayScreenshot,
            selector: #selector(captureDisplay)
        )
        addAction(
            "Capture Region…",
            symbol: "rectangle.dashed",
            shortcut: .regionScreenshot,
            selector: #selector(captureRegion)
        )
        addAction(
            "Capture Window…",
            symbol: "macwindow",
            shortcut: .windowScreenshot,
            selector: #selector(captureWindow)
        )

        addItem(.separator())
        addSectionHeader("Screen Recording")
        addAction(
            "Record Display",
            symbol: "record.circle",
            shortcut: .displayRecording,
            selector: #selector(recordDisplay),
            enabled: !screenRecorder.isActive
        )
        addAction(
            "Record Region…",
            symbol: "rectangle.dashed.badge.record",
            shortcut: .regionRecording,
            selector: #selector(recordRegion),
            enabled: !screenRecorder.isActive
        )
        addAction(
            "Stop Recording",
            symbol: "stop.circle.fill",
            selector: #selector(stopRecording),
            enabled: screenRecorder.isActive
        )

        addItem(.separator())
        addAction("Settings…", symbol: "gearshape", selector: #selector(showSettings))
        addAction("Show Captures", symbol: "folder", selector: #selector(showCaptures))
        addItem(.separator())

        let quit = NSMenuItem(title: "Quit SnipMac", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        addItem(quit)
    }

    @objc private func captureDisplay() {
        afterMenuCloses { ScreenCaptureManager.shared.captureDisplay() }
    }

    @objc private func captureRegion() {
        afterMenuCloses { self.overlayWindowManager.showRegionSelector(for: .screenshot) }
    }

    @objc private func captureWindow() {
        afterMenuCloses { self.overlayWindowManager.showWindowSelector() }
    }

    @objc private func recordDisplay() {
        afterMenuCloses { self.screenRecorder.startRecordingDisplayUnderPointer() }
    }

    @objc private func recordRegion() {
        afterMenuCloses { self.overlayWindowManager.showRegionSelector(for: .screenRecording) }
    }

    @objc private func stopRecording() {
        screenRecorder.stopRecording()
    }

    @objc private func showSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showCaptures() {
        NSWorkspace.shared.open(CaptureStore.shared.captureDirectory)
    }

    @objc private func recordingStateChanged() {
        rebuild()
    }

    private func afterMenuCloses(_ action: @escaping @MainActor () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { action() }
    }

    private func addSectionHeader(_ title: String) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        addItem(item)
    }

    private func addAction(
        _ title: String,
        symbol: String,
        shortcut: GlobalShortcutManager.Action? = nil,
        selector: Selector,
        enabled: Bool = true
    ) {
        let visibleTitle = shortcut.map { "\(title)    \($0.displayName)" } ?? title
        let item = NSMenuItem(title: visibleTitle, action: selector, keyEquivalent: "")
        item.target = self
        item.isEnabled = enabled
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
        item.image?.isTemplate = true
        addItem(item)
    }
}

extension Notification.Name {
    static let recordingStateChanged = Notification.Name("SnipMacRecordingStateChanged")
}
