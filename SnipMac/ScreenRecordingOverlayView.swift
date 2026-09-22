import AppKit
import SwiftUI

@MainActor
final class RecordingControlManager {
    static let shared = RecordingControlManager()

    private var countdownPanel: NSPanel?
    private var controlPanel: NSPanel?
    private var countdownTask: Task<Void, Never>?

    private init() {}

    func runCountdown(on screen: NSScreen, completion: @escaping @MainActor () -> Void) {
        cancelCountdown()
        let seconds = UserDefaults.standard.object(forKey: "recordingCountdown") as? Int ?? 3
        guard seconds > 0 else {
            completion()
            return
        }

        let panel = makePanel(size: CGSize(width: 170, height: 170), level: .screenSaver)
        countdownPanel = panel
        center(panel, on: screen)
        panel.orderFrontRegardless()

        countdownTask = Task { @MainActor [weak self, weak panel] in
            for value in stride(from: seconds, through: 1, by: -1) {
                guard !Task.isCancelled else { return }
                panel?.contentView = NSHostingView(rootView: RecordingCountdownView(value: value))
                try? await Task.sleep(for: .seconds(1))
            }
            guard !Task.isCancelled else { return }
            self?.countdownPanel?.orderOut(nil)
            self?.countdownPanel = nil
            completion()
        }
    }

    func showControls(on screen: NSScreen) {
        hideControls()
        let size = CGSize(width: 250, height: 54)
        let panel = makePanel(size: size, level: .floating)
        panel.contentView = NSHostingView(rootView: RecordingControlView(startedAt: Date()))
        panel.setFrameOrigin(CGPoint(
            x: screen.visibleFrame.midX - size.width / 2,
            y: screen.visibleFrame.maxY - size.height - 18
        ))
        panel.orderFrontRegardless()
        controlPanel = panel
    }

    func hideControls() {
        controlPanel?.orderOut(nil)
        controlPanel = nil
    }

    func cancelCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
        countdownPanel?.orderOut(nil)
        countdownPanel = nil
    }

    private func makePanel(size: CGSize, level: NSWindow.Level) -> NSPanel {
        let panel = RecordingPanel(
            contentRect: CGRect(origin: .zero, size: size),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = level
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        return panel
    }

    private func center(_ panel: NSPanel, on screen: NSScreen) {
        panel.setFrameOrigin(CGPoint(
            x: screen.frame.midX - panel.frame.width / 2,
            y: screen.frame.midY - panel.frame.height / 2
        ))
    }
}

private final class RecordingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

private struct RecordingCountdownView: View {
    let value: Int

    var body: some View {
        ZStack {
            Circle().fill(.black.opacity(0.78))
            Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1)
            Text("\(value)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(10)
    }
}

private struct RecordingControlView: View {
    let startedAt: Date
    @State private var isPaused = false

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(.red)
                .frame(width: 10, height: 10)

            TimelineView(.periodic(from: startedAt, by: 1)) { context in
                Text(elapsed(at: context.date))
                    .font(.system(.body, design: .monospaced).weight(.medium))
                    .frame(width: 58, alignment: .leading)
            }

            Divider().frame(height: 22)

            Button {
                if isPaused {
                    ScreenRecorder.shared.resumeRecording()
                } else {
                    ScreenRecorder.shared.pauseRecording()
                }
                isPaused.toggle()
            } label: {
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.borderless)
            .help(isPaused ? "Resume recording" : "Pause recording")

            Button {
                ScreenRecorder.shared.stopRecording()
            } label: {
                Image(systemName: "stop.fill")
                    .foregroundStyle(.red)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.borderless)
            .help("Stop recording")
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThickMaterial)
        .clipShape(Capsule())
        .overlay { Capsule().strokeBorder(.white.opacity(0.16)) }
        .padding(4)
    }

    private func elapsed(at date: Date) -> String {
        let seconds = max(0, Int(date.timeIntervalSince(startedAt)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
