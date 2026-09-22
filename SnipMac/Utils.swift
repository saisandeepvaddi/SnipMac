import AppKit
import Carbon
import Foundation

enum CaptureKind {
    case screenshot
    case screenRecording
}

enum CaptureScope {
    case display
    case region
    case window
}

struct WindowCandidate {
    let id: CGWindowID
    let quartzBounds: CGRect
    let appKitBounds: CGRect
}

enum CaptureError: LocalizedError {
    case permissionDenied
    case captureFailed
    case invalidRegion
    case regionSpansDisplays

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Screen Recording permission is required to capture the screen."
        case .captureFailed:
            return "SnipMac could not capture the selected content."
        case .invalidRegion:
            return "Select a region that is at least 2 × 2 points."
        case .regionSpansDisplays:
            return "A screen recording region must stay within one display."
        }
    }
}

enum CaptureGeometry {
    static var virtualScreenFrame: CGRect {
        NSScreen.screens.reduce(.null) { $0.union($1.frame) }
    }

    static func quartzRect(fromAppKitRect rect: CGRect) -> CGRect {
        let mainDisplayHeight = CGDisplayBounds(CGMainDisplayID()).height
        return CGRect(
            x: rect.minX,
            y: mainDisplayHeight - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    static func appKitRect(fromQuartzRect rect: CGRect) -> CGRect {
        let mainDisplayHeight = CGDisplayBounds(CGMainDisplayID()).height
        return CGRect(
            x: rect.minX,
            y: mainDisplayHeight - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    static func screen(containing point: CGPoint) -> NSScreen? {
        NSScreen.screens.first(where: { $0.frame.contains(point) })
            ?? NSScreen.screens.min(by: {
                distance(from: point, to: $0.frame) < distance(from: point, to: $1.frame)
            })
    }

    static func displayID(for screen: NSScreen) -> CGDirectDisplayID? {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)
            .map { CGDirectDisplayID($0.uint32Value) }
    }

    static func recordingCropRect(_ globalRect: CGRect, on screen: NSScreen) -> CGRect {
        let local = CGRect(
            x: globalRect.minX - screen.frame.minX,
            y: globalRect.minY - screen.frame.minY,
            width: globalRect.width,
            height: globalRect.height
        )
        let scale = screen.backingScaleFactor
        return CGRect(
            x: local.minX * scale,
            y: (screen.frame.height - local.maxY) * scale,
            width: local.width * scale,
            height: local.height * scale
        )
    }

    private static func distance(from point: CGPoint, to rect: CGRect) -> CGFloat {
        let dx = max(rect.minX - point.x, 0, point.x - rect.maxX)
        let dy = max(rect.minY - point.y, 0, point.y - rect.maxY)
        return hypot(dx, dy)
    }
}

@MainActor
enum UserFacingAlert {
    static func show(title: String, message: String, settingsURL: URL? = nil) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        if settingsURL != nil {
            alert.addButton(withTitle: "Open System Settings")
        }
        if alert.runModal() == .alertSecondButtonReturn, let settingsURL {
            NSWorkspace.shared.open(settingsURL)
        }
    }
}

extension URL {
    static let screenRecordingSettings = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
    )!

    static let microphoneSettings = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
    )!
}

@MainActor
final class GlobalShortcutManager {
    enum Action: UInt32, CaseIterable {
        case displayScreenshot = 1
        case regionScreenshot
        case windowScreenshot
        case displayRecording
        case regionRecording

        var keyCode: UInt32 {
            switch self {
            case .displayScreenshot: return UInt32(kVK_ANSI_1)
            case .regionScreenshot: return UInt32(kVK_ANSI_2)
            case .windowScreenshot: return UInt32(kVK_ANSI_3)
            case .displayRecording: return UInt32(kVK_ANSI_4)
            case .regionRecording: return UInt32(kVK_ANSI_5)
            }
        }

        var displayName: String {
            switch self {
            case .displayScreenshot: return "⌃⇧1"
            case .regionScreenshot: return "⌃⇧2"
            case .windowScreenshot: return "⌃⇧3"
            case .displayRecording: return "⌃⇧4"
            case .regionRecording: return "⌃⇧5"
            }
        }
    }

    private var hotKeyRefs: [EventHotKeyRef?] = []
    private var eventHandler: EventHandlerRef?
    var onAction: ((Action) -> Void)?

    func registerDefaults() {
        unregisterAll()
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, context in
                guard let event, let context else { return noErr }
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                guard status == noErr,
                      let action = Action(rawValue: hotKeyID.id)
                else { return status }
                let manager = Unmanaged<GlobalShortcutManager>
                    .fromOpaque(context)
                    .takeUnretainedValue()
                manager.onAction?(action)
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        for action in Action.allCases {
            var reference: EventHotKeyRef?
            let identifier = EventHotKeyID(signature: OSType(0x534E4950), id: action.rawValue)
            RegisterEventHotKey(
                action.keyCode,
                UInt32(controlKey | shiftKey),
                identifier,
                GetApplicationEventTarget(),
                0,
                &reference
            )
            hotKeyRefs.append(reference)
        }
    }

    func unregisterAll() {
        hotKeyRefs.compactMap { $0 }.forEach { UnregisterEventHotKey($0) }
        hotKeyRefs.removeAll()
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    deinit {
        hotKeyRefs.compactMap { $0 }.forEach { UnregisterEventHotKey($0) }
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }
}
