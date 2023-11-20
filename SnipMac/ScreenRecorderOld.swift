//
//  ScreenRecorder.swift
//  SnipMac
//
//  Created by Sai Sandeep Vaddi on 11/16/23.
//

import AppKit
import AVFoundation
import Foundation

class ScreenRecorder: NSObject {
    static let shared = ScreenRecorder()
    let overlayWindowManager = OverlayWindowManager.shared

    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var screenInput: AVCaptureScreenInput?

    override init() {
        super.init()
    }

    func getNewOutputFileURL() -> URL {
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "SnipMacScreenRecording \(timestamp).mp4"
        return desktopURL.appendingPathComponent(filename)
    }

    func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high
        screenInput = AVCaptureScreenInput(displayID: CGMainDisplayID())

        videoOutput = AVCaptureMovieFileOutput()
    }

    func startRecordingMainScreen() {
        startRecording(of: CGDisplayBounds(CGMainDisplayID()))
    }

    func startRecording(of area: CGRect?) {
        setupCaptureSession()
        print("Started")
        guard let captureSession = captureSession, let movieOutput = videoOutput, let input = screenInput else { return }

        if area != nil {
            input.cropRect = area ?? CGDisplayBounds(CGMainDisplayID())
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        // Add the movie file output
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
        }

        // Start the session
        captureSession.startRunning()

        // Start recording to a file
        movieOutput.startRecording(to: getNewOutputFileURL(), recordingDelegate: self)
    }

    func stopRecording() {
        videoOutput?.stopRecording()
        captureSession?.stopRunning()
        captureSession = nil
        videoOutput = nil
        print("Stopping recording")
        if (overlayWindowManager.overlayWindow) != nil {
            overlayWindowManager.hideOverlayWindow()
        }
    }
}

extension ScreenRecorder: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                    didStartRecordingTo fileURL: URL,
                    from connections: [AVCaptureConnection])
    {
        print("Recording started")
    }

    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?)
    {
        if let error = error {
            print("Recording error: \(error)")
        }
        // Handle completion of recording
        print("Recording finished: \(outputFileURL.path)")
        NSWorkspace.shared.open(outputFileURL)
    }
}
