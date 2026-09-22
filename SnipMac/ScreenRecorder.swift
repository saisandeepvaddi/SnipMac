import AppKit
import AVFoundation

@MainActor
final class ScreenRecorder: NSObject {
    enum State: Equatable {
        case idle
        case preparing
        case recording
        case paused
        case finalizing
        case failed(String)
    }

    static let shared = ScreenRecorder()

    private(set) var state: State = .idle {
        didSet { NotificationCenter.default.post(name: .recordingStateChanged, object: self) }
    }

    var isActive: Bool {
        switch state {
        case .idle, .failed: return false
        case .preparing, .recording, .paused, .finalizing: return true
        }
    }

    var includesMicrophone: Bool {
        get { UserDefaults.standard.bool(forKey: "includesMicrophone") }
        set { UserDefaults.standard.set(newValue, forKey: "includesMicrophone") }
    }

    private var captureSession: AVCaptureSession?
    private var movieOutput: AVCaptureMovieFileOutput?
    private var outputURL: URL?
    private var recordingScreen: NSScreen?

    func startRecordingMainScreen() {
        guard let screen = NSScreen.main else { return }
        start(on: screen, region: nil)
    }

    func startRecordingDisplayUnderPointer() {
        guard let screen = CaptureGeometry.screen(containing: NSEvent.mouseLocation) else { return }
        start(on: screen, region: nil)
    }

    func startRecording(of globalRect: CGRect) {
        let containingScreens = NSScreen.screens.filter { $0.frame.contains(globalRect) }
        guard containingScreens.count == 1, let screen = containingScreens.first else {
            present(.regionSpansDisplays)
            return
        }
        guard globalRect.width >= 2, globalRect.height >= 2 else {
            present(.invalidRegion)
            return
        }
        start(on: screen, region: globalRect)
    }

    func pauseRecording() {
        guard state == .recording else { return }
        movieOutput?.pauseRecording()
        state = .paused
    }

    func resumeRecording() {
        guard state == .paused else { return }
        movieOutput?.resumeRecording()
        state = .recording
    }

    func stopRecording() {
        guard state == .recording || state == .paused else { return }
        state = .finalizing
        movieOutput?.stopRecording()
    }

    private func start(on screen: NSScreen, region: CGRect?) {
        guard state == .idle || isFailure else { return }
        guard CGPreflightScreenCaptureAccess() || CGRequestScreenCaptureAccess() else {
            present(.permissionDenied, settingsURL: .screenRecordingSettings)
            return
        }

        state = .preparing
        if includesMicrophone {
            requestMicrophoneAccess { [weak self] allowed in
                guard let self else { return }
                if allowed {
                    self.beginCountdown(on: screen, region: region)
                } else {
                    self.state = .idle
                    UserFacingAlert.show(
                        title: "Microphone Unavailable",
                        message: "Turn off microphone recording or grant access in System Settings.",
                        settingsURL: .microphoneSettings
                    )
                }
            }
        } else {
            beginCountdown(on: screen, region: region)
        }
    }

    private func beginCountdown(on screen: NSScreen, region: CGRect?) {
        recordingScreen = screen
        RecordingControlManager.shared.runCountdown(on: screen) { [weak self] in
            self?.configureAndStart(on: screen, region: region)
        }
    }

    private var isFailure: Bool {
        if case .failed = state { return true }
        return false
    }

    private func requestMicrophoneAccess(completion: @escaping @MainActor (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { allowed in
                Task { @MainActor in completion(allowed) }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    private func configureAndStart(on screen: NSScreen, region: CGRect?) {
        guard let displayID = CaptureGeometry.displayID(for: screen) else {
            fail("The selected display is unavailable.")
            return
        }

        let session = AVCaptureSession()
        session.sessionPreset = .high

        guard let screenInput = AVCaptureScreenInput(displayID: displayID) else {
            fail("The selected display cannot be recorded.")
            return
        }
        screenInput.minFrameDuration = CMTime(value: 1, timescale: 60)
        screenInput.capturesCursor = true
        screenInput.capturesMouseClicks = true
        if let region {
            screenInput.cropRect = CaptureGeometry.recordingCropRect(region, on: screen)
        }
        guard session.canAddInput(screenInput) else {
            fail("SnipMac could not add the selected display to the recording.")
            return
        }
        session.addInput(screenInput)

        if includesMicrophone, let microphone = AVCaptureDevice.default(for: .audio) {
            do {
                let input = try AVCaptureDeviceInput(device: microphone)
                if session.canAddInput(input) { session.addInput(input) }
            } catch {
                fail(error.localizedDescription)
                return
            }
        }

        let output = AVCaptureMovieFileOutput()
        guard session.canAddOutput(output) else {
            fail("SnipMac could not create a recording output.")
            return
        }
        session.addOutput(output)

        do {
            let url = try CaptureStore.shared.recordingURL()
            captureSession = session
            movieOutput = output
            outputURL = url
            session.startRunning()
            output.startRecording(to: url, recordingDelegate: self)
        } catch {
            fail(error.localizedDescription)
        }
    }

    private func finishSession() {
        RecordingControlManager.shared.cancelCountdown()
        RecordingControlManager.shared.hideControls()
        captureSession?.stopRunning()
        captureSession = nil
        movieOutput = nil
        outputURL = nil
    }

    private func fail(_ message: String) {
        finishSession()
        state = .failed(message)
        UserFacingAlert.show(title: "Recording Unavailable", message: message)
    }

    private func present(_ error: CaptureError, settingsURL: URL? = nil) {
        state = .idle
        UserFacingAlert.show(
            title: "Recording Unavailable",
            message: error.localizedDescription,
            settingsURL: settingsURL
        )
    }
}

extension ScreenRecorder: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didStartRecordingTo fileURL: URL,
        from connections: [AVCaptureConnection]
    ) {
        Task { @MainActor in
            self.state = .recording
            if let screen = self.recordingScreen {
                RecordingControlManager.shared.showControls(on: screen)
            }
        }
    }

    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        Task { @MainActor in
            self.finishSession()
            if let error {
                self.state = .failed(error.localizedDescription)
                UserFacingAlert.show(title: "Recording Couldn’t Be Finalized", message: error.localizedDescription)
            } else {
                self.state = .idle
                QuickAccessPreviewManager.shared.showRecording(fileURL: outputFileURL)
            }
            self.recordingScreen = nil
        }
    }
}
