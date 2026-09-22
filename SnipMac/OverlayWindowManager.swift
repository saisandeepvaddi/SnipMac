import AppKit

@MainActor
final class OverlayWindowManager {
    static let shared = OverlayWindowManager()

    private(set) var overlayWindow: NSWindow?
    weak var mainWindow: NSWindow?

    private init() {}

    func showRegionSelector(for kind: CaptureKind) {
        hideOverlayWindow()

        let frame = CaptureGeometry.virtualScreenFrame
        let panel = SelectionPanel(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hasShadow = false

        let selectionView = RegionSelectionView(frame: CGRect(origin: .zero, size: frame.size))
        selectionView.onCancel = { [weak self] in self?.hideOverlayWindow() }
        selectionView.onConfirm = { [weak self, weak panel] localRect in
            guard let self, let panel else { return }
            let globalRect = panel.convertToScreen(localRect)
            self.hideOverlayWindow()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                switch kind {
                case .screenshot:
                    ScreenCaptureManager.shared.captureRegion(globalRect)
                case .screenRecording:
                    ScreenRecorder.shared.startRecording(of: globalRect)
                }
            }
        }
        panel.contentView = selectionView
        overlayWindow = panel
        NSApp.activate(ignoringOtherApps: true)
        panel.orderFrontRegardless()
        panel.makeKey()
        panel.makeFirstResponder(selectionView)
        panel.invalidateCursorRects(for: selectionView)
    }

    func showWindowSelector() {
        hideOverlayWindow()

        let frame = CaptureGeometry.virtualScreenFrame
        let panel = SelectionPanel(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hasShadow = false
        panel.acceptsMouseMovedEvents = true

        let selectionView = WindowSelectionView(frame: CGRect(origin: .zero, size: frame.size))
        selectionView.onCancel = { [weak self] in self?.hideOverlayWindow() }
        selectionView.onConfirm = { [weak self] candidate in
            self?.hideOverlayWindow()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                ScreenCaptureManager.shared.captureWindow(candidate)
            }
        }
        panel.contentView = selectionView
        overlayWindow = panel
        NSApp.activate(ignoringOtherApps: true)
        panel.orderFrontRegardless()
        panel.makeKey()
        panel.makeFirstResponder(selectionView)
        panel.invalidateCursorRects(for: selectionView)
        selectionView.refreshCandidate()
    }

    func hideOverlayWindow() {
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
    }

    func hideMainWindow() { mainWindow?.orderOut(nil) }
    func showMainWindow() { mainWindow?.makeKeyAndOrderFront(nil) }
}

private final class WindowSelectionView: NSView {
    var onConfirm: ((WindowCandidate) -> Void)?
    var onCancel: (() -> Void)?

    private var candidate: WindowCandidate?
    private var trackingAreaReference: NSTrackingArea?

    override var acceptsFirstResponder: Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaReference { removeTrackingArea(trackingAreaReference) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingAreaReference = area
    }

    override func mouseMoved(with event: NSEvent) {
        refreshCandidate()
    }

    override func mouseDown(with event: NSEvent) {
        if let candidate { onConfirm?(candidate) }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel?()
        } else {
            super.keyDown(with: event)
        }
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }

    func refreshCandidate() {
        guard let window else { return }
        let localPoint = convert(window.mouseLocationOutsideOfEventStream, from: nil)
        let globalPoint = window.convertPoint(toScreen: localPoint)
        candidate = ScreenCaptureManager.shared.windowCandidate(at: globalPoint)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let highlight = candidate.map { candidate in
            window?.convertFromScreen(candidate.appKitBounds) ?? .zero
        } ?? .zero

        let shade = NSBezierPath(rect: bounds)
        if !highlight.isEmpty { shade.appendRect(highlight) }
        shade.windingRule = .evenOdd
        NSColor.black.withAlphaComponent(0.38).setFill()
        shade.fill()

        if !highlight.isEmpty {
            NSColor.systemBlue.setStroke()
            let border = NSBezierPath(roundedRect: highlight.insetBy(dx: -2, dy: -2), xRadius: 8, yRadius: 8)
            border.lineWidth = 4
            border.stroke()
        }

        let text = "Move over a window and click • Esc to cancel" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: NSColor.white,
            .backgroundColor: NSColor.black.withAlphaComponent(0.72)
        ]
        let size = text.size(withAttributes: attributes)
        text.draw(
            at: CGPoint(x: bounds.midX - size.width / 2, y: bounds.minY + 42),
            withAttributes: attributes
        )
    }
}

private final class SelectionPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

private final class RegionSelectionView: NSView {
    enum Handle: CaseIterable {
        case topLeft, top, topRight, right, bottomRight, bottom, bottomLeft, left
    }

    enum Interaction {
        case drawing(anchor: CGPoint)
        case moving(offset: CGPoint)
        case resizing(handle: Handle, original: CGRect, anchor: CGPoint)
    }

    var onConfirm: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private var selection: CGRect = .zero
    private var interaction: Interaction?
    private let handleSize: CGFloat = 10

    override var acceptsFirstResponder: Bool { true }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        if event.clickCount == 2, selection.contains(point), isValidSelection {
            onConfirm?(selection)
            return
        }
        if let handle = handle(at: point) {
            interaction = .resizing(handle: handle, original: selection, anchor: point)
        } else if selection.contains(point) {
            interaction = .moving(offset: CGPoint(x: point.x - selection.minX, y: point.y - selection.minY))
        } else {
            selection = CGRect(origin: point, size: .zero)
            interaction = .drawing(anchor: point)
        }
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard let interaction else { return }

        switch interaction {
        case let .drawing(anchor):
            selection = rectangle(from: anchor, to: point).intersection(bounds)
        case let .moving(offset):
            let proposed = CGRect(
                origin: CGPoint(x: point.x - offset.x, y: point.y - offset.y),
                size: selection.size
            )
            selection.origin = clampedOrigin(for: proposed)
        case let .resizing(handle, original, anchor):
            selection = resized(original, with: handle, translation: CGPoint(
                x: point.x - anchor.x,
                y: point.y - anchor.y
            )).standardized.intersection(bounds)
        }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let shouldCapture: Bool
        if case .drawing = interaction {
            shouldCapture = isValidSelection
        } else {
            shouldCapture = false
        }
        interaction = nil
        if shouldCapture {
            onConfirm?(selection)
            return
        }
        window?.makeFirstResponder(self)
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 36 where isValidSelection, 76 where isValidSelection:
            onConfirm?(selection)
        case 53:
            onCancel?()
        case 123 where isValidSelection,
             124 where isValidSelection,
             125 where isValidSelection,
             126 where isValidSelection:
            nudgeSelection(for: event)
        default:
            super.keyDown(with: event)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let shade = NSBezierPath(rect: bounds)
        if isValidSelection { shade.appendRect(selection) }
        shade.windingRule = .evenOdd
        NSColor.black.withAlphaComponent(0.38).setFill()
        shade.fill()

        guard isValidSelection else {
            drawInstructions()
            return
        }

        NSColor.white.setStroke()
        let border = NSBezierPath(rect: selection.insetBy(dx: 0.5, dy: 0.5))
        border.lineWidth = 1
        border.stroke()

        NSColor.white.setFill()
        for rect in handleRects().values {
            NSBezierPath(ovalIn: rect).fill()
        }
        drawDimensions()
    }

    private var isValidSelection: Bool { selection.width >= 2 && selection.height >= 2 }

    private func rectangle(from start: CGPoint, to end: CGPoint) -> CGRect {
        CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }

    private func handleRects() -> [Handle: CGRect] {
        let half = handleSize / 2
        let centers: [Handle: CGPoint] = [
            .topLeft: CGPoint(x: selection.minX, y: selection.maxY),
            .top: CGPoint(x: selection.midX, y: selection.maxY),
            .topRight: CGPoint(x: selection.maxX, y: selection.maxY),
            .right: CGPoint(x: selection.maxX, y: selection.midY),
            .bottomRight: CGPoint(x: selection.maxX, y: selection.minY),
            .bottom: CGPoint(x: selection.midX, y: selection.minY),
            .bottomLeft: CGPoint(x: selection.minX, y: selection.minY),
            .left: CGPoint(x: selection.minX, y: selection.midY)
        ]
        return centers.mapValues { CGRect(x: $0.x - half, y: $0.y - half, width: handleSize, height: handleSize) }
    }

    private func handle(at point: CGPoint) -> Handle? {
        guard isValidSelection else { return nil }
        return handleRects().first(where: { $0.value.insetBy(dx: -3, dy: -3).contains(point) })?.key
    }

    private func resized(_ rect: CGRect, with handle: Handle, translation: CGPoint) -> CGRect {
        var result = rect
        if [.topLeft, .left, .bottomLeft].contains(handle) {
            result.origin.x += translation.x
            result.size.width -= translation.x
        }
        if [.topRight, .right, .bottomRight].contains(handle) { result.size.width += translation.x }
        if [.bottomLeft, .bottom, .bottomRight].contains(handle) {
            result.origin.y += translation.y
            result.size.height -= translation.y
        }
        if [.topLeft, .top, .topRight].contains(handle) { result.size.height += translation.y }
        return result
    }

    private func clampedOrigin(for proposed: CGRect) -> CGPoint {
        CGPoint(
            x: min(max(proposed.minX, bounds.minX), bounds.maxX - proposed.width),
            y: min(max(proposed.minY, bounds.minY), bounds.maxY - proposed.height)
        )
    }

    private func nudgeSelection(for event: NSEvent) {
        let amount: CGFloat = event.modifierFlags.contains(.shift) ? 10 : 1
        var proposed = selection
        switch event.keyCode {
        case 123: proposed.origin.x -= amount
        case 124: proposed.origin.x += amount
        case 125: proposed.origin.y -= amount
        case 126: proposed.origin.y += amount
        default: return
        }
        selection.origin = clampedOrigin(for: proposed)
        needsDisplay = true
    }

    private func drawInstructions() {
        let text = "Drag to capture • Esc to cancel" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let size = text.size(withAttributes: attributes)
        text.draw(
            at: CGPoint(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2),
            withAttributes: attributes
        )
    }

    private func drawDimensions() {
        let text = "\(Int(selection.width)) × \(Int(selection.height))" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white,
            .backgroundColor: NSColor.black.withAlphaComponent(0.72)
        ]
        text.draw(
            at: CGPoint(x: selection.midX - text.size(withAttributes: attributes).width / 2, y: selection.minY - 24),
            withAttributes: attributes
        )
    }
}
