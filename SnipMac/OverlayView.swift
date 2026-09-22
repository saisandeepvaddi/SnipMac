import AppKit
import SwiftUI

@MainActor
final class QuickAccessPreviewManager {
    static let shared = QuickAccessPreviewManager()

    private var panel: NSPanel?
    private var currentImage: NSImage?
    private var currentURL: URL?

    private init() {}

    func show(image: CGImage, fileURL: URL) {
        show(image: NSImage(cgImage: image, size: .zero), fileURL: fileURL)
    }

    func showRecording(fileURL: URL) {
        let image = NSImage(
            systemSymbolName: "play.rectangle.fill",
            accessibilityDescription: "Screen recording"
        ) ?? NSImage(size: CGSize(width: 180, height: 120))
        show(image: image, fileURL: fileURL)
    }

    private func show(image: NSImage, fileURL: URL) {
        currentImage = image
        currentURL = fileURL

        let view = QuickAccessPreview(
            image: currentImage!,
            fileURL: fileURL,
            copy: { [weak self] in self?.copyCurrentImage() },
            reveal: { NSWorkspace.shared.activateFileViewerSelecting([fileURL]) },
            open: { NSWorkspace.shared.open(fileURL) },
            trash: { [weak self] in self?.trashCurrentCapture() },
            dismiss: { [weak self] in self?.dismiss() }
        )
        let hostingView = NSHostingView(rootView: view)
        let size = previewSize(for: image)

        if panel == nil {
            let panel = NSPanel(
                contentRect: CGRect(origin: .zero, size: size),
                styleMask: [.nonactivatingPanel, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.hidesOnDeactivate = false
            self.panel = panel
        }

        panel?.contentView = hostingView
        panel?.setContentSize(size)
        positionPanel(size: size)
        panel?.orderFrontRegardless()
    }

    func dismiss() {
        panel?.orderOut(nil)
    }

    private func copyCurrentImage() {
        guard let currentImage else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([currentImage])
    }

    private func trashCurrentCapture() {
        guard let currentURL else { return }
        do {
            try FileManager.default.trashItem(at: currentURL, resultingItemURL: nil)
            dismiss()
        } catch {
            UserFacingAlert.show(title: "Couldn’t Move Capture to Trash", message: error.localizedDescription)
        }
    }

    private func previewSize(for image: NSImage) -> CGSize {
        let maxWidth: CGFloat = 300
        let maxHeight: CGFloat = 220
        let aspect = image.size.width / max(image.size.height, 1)
        let imageHeight = min(maxHeight, maxWidth / max(aspect, 0.1))
        return CGSize(width: maxWidth, height: max(150, imageHeight + 46))
    }

    private func positionPanel(size: CGSize) {
        let pointer = NSEvent.mouseLocation
        let screen = CaptureGeometry.screen(containing: pointer) ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else { return }
        panel?.setFrameOrigin(CGPoint(
            x: visibleFrame.maxX - size.width - 18,
            y: visibleFrame.minY + 18
        ))
    }
}

private struct QuickAccessPreview: View {
    let image: NSImage
    let fileURL: URL
    let copy: () -> Void
    let reveal: () -> Void
    let open: () -> Void
    let trash: () -> Void
    let dismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: open) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.12))
            }
            .buttonStyle(.plain)
            .help("Open screenshot")

            HStack(spacing: 14) {
                actionButton("doc.on.doc", help: "Copy", action: copy)
                actionButton("folder", help: "Show in Finder", action: reveal)
                Spacer(minLength: 0)
                Text(fileURL.lastPathComponent)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                actionButton("trash", help: "Move to Trash", action: trash)
                actionButton("xmark", help: "Dismiss", action: dismiss)
            }
            .padding(.horizontal, 12)
            .frame(height: 42)
        }
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.16))
        }
        .padding(8)
    }

    private func actionButton(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.borderless)
        .help(help)
    }
}
