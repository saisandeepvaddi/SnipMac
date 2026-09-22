import AppKit
import CoreGraphics
import Foundation

@MainActor
final class ScreenCaptureManager {
    static let shared = ScreenCaptureManager()

    private init() {}

    static func takeScreenshot(of area: CGRect? = nil) {
        if let area {
            shared.captureRegion(area)
        } else {
            shared.captureDisplay()
        }
    }

    func captureDisplay(at point: CGPoint = NSEvent.mouseLocation) {
        guard ensurePermission(),
              let screen = CaptureGeometry.screen(containing: point),
              let displayID = CaptureGeometry.displayID(for: screen),
              let image = CGDisplayCreateImage(displayID)
        else {
            if CGPreflightScreenCaptureAccess() { present(.captureFailed) }
            return
        }
        finish(image)
    }

    func captureRegion(_ appKitRect: CGRect) {
        guard appKitRect.width >= 2, appKitRect.height >= 2 else {
            present(.invalidRegion)
            return
        }
        guard ensurePermission() else { return }
        let quartzRect = CaptureGeometry.quartzRect(fromAppKitRect: appKitRect)
        guard let image = CGWindowListCreateImage(
            quartzRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution, .boundsIgnoreFraming]
        ) else {
            present(.captureFailed)
            return
        }
        finish(image)
    }

    func captureWindow(at point: CGPoint = NSEvent.mouseLocation) {
        guard ensurePermission() else { return }
        guard let candidate = windowCandidate(at: point) else {
            present(.captureFailed)
            return
        }
        captureWindow(candidate)
    }

    func captureWindow(_ candidate: WindowCandidate) {
        guard ensurePermission(),
              let image = CGWindowListCreateImage(
                  candidate.quartzBounds,
                  .optionIncludingWindow,
                  candidate.id,
                  [.bestResolution, .boundsIgnoreFraming]
              )
        else {
            present(.captureFailed)
            return
        }
        finish(image)
    }

    private func ensurePermission() -> Bool {
        if CGPreflightScreenCaptureAccess() { return true }
        if CGRequestScreenCaptureAccess() { return true }
        present(.permissionDenied, settingsURL: .screenRecordingSettings)
        return false
    }

    func windowCandidate(at appKitPoint: CGPoint) -> WindowCandidate? {
        let quartzPoint = CGPoint(
            x: appKitPoint.x,
            y: CGDisplayBounds(CGMainDisplayID()).height - appKitPoint.y
        )
        guard let windows = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else { return nil }

        let ownPID = ProcessInfo.processInfo.processIdentifier
        guard let window = windows.first(where: { window in
            guard (window[kCGWindowLayer as String] as? NSNumber)?.intValue == 0,
                  (window[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value != ownPID,
                  let boundsValue = window[kCGWindowBounds as String],
                  let bounds = CGRect(dictionaryRepresentation: boundsValue as! CFDictionary)
            else { return false }
            return bounds.contains(quartzPoint)
        }),
        let number = window[kCGWindowNumber as String] as? NSNumber,
        let boundsValue = window[kCGWindowBounds as String],
        let quartzBounds = CGRect(dictionaryRepresentation: boundsValue as! CFDictionary)
        else { return nil }

        return WindowCandidate(
            id: CGWindowID(number.uint32Value),
            quartzBounds: quartzBounds,
            appKitBounds: CaptureGeometry.appKitRect(fromQuartzRect: quartzBounds)
        )
    }

    private func finish(_ image: CGImage) {
        do {
            let url = try CaptureStore.shared.savePNG(image)
            copyToPasteboard(image)
            QuickAccessPreviewManager.shared.show(image: image, fileURL: url)
        } catch {
            UserFacingAlert.show(title: "Couldn’t Save Capture", message: error.localizedDescription)
        }
    }

    private func copyToPasteboard(_ image: CGImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([NSImage(cgImage: image, size: .zero)])
    }

    private func present(_ error: CaptureError, settingsURL: URL? = nil) {
        UserFacingAlert.show(
            title: "Capture Unavailable",
            message: error.localizedDescription,
            settingsURL: settingsURL
        )
    }
}

final class CaptureStore {
    static let shared = CaptureStore()
    private let fileManager = FileManager.default

    var captureDirectory: URL {
        if let path = UserDefaults.standard.string(forKey: "captureDirectory"), !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        let pictures = fileManager.urls(for: .picturesDirectory, in: .userDomainMask)[0]
        return pictures.appendingPathComponent("SnipMac", isDirectory: true)
    }

    func savePNG(_ image: CGImage) throws -> URL {
        let directory = captureDirectory
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("Screenshot \(Self.timestamp()).png")
        let representation = NSBitmapImageRep(cgImage: image)
        guard let data = representation.representation(using: .png, properties: [:]) else {
            throw CaptureError.captureFailed
        }
        try data.write(to: url, options: .atomic)
        return url
    }

    func recordingURL() throws -> URL {
        let directory = captureDirectory
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("Recording \(Self.timestamp()).mp4")
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        return formatter.string(from: Date())
    }
}
