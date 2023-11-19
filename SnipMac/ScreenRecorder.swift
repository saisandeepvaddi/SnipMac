//
//  ScreenRecorder.swift
//  SnipMac
//
//  Created by Sai Sandeep Vaddi on 11/16/23.
//

import AVFoundation
import Foundation

class ScreenRecorder: NSObject {
    static let shared = ScreenRecorder()
    private var captureSession: AVCaptureSession?
    private var movieOutput: AVCaptureMovieFileOutput?
    private var destinationURL: URL
    let overlayWindowManager = OverlayWindowManager.shared
    override init() {
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "SnipMacScreenRecording \(timestamp).mp4"
        destinationURL = desktopURL.appendingPathComponent(filename)
        super.init()
        setupCaptureSession()
    }

    func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high

        movieOutput = AVCaptureMovieFileOutput()
    }

    func startRecordingMainScreen() {
        startRecording(of: CGDisplayBounds(CGMainDisplayID()))
    }

    func startRecording(of area: CGRect?) {
        guard let captureSession = captureSession, let movieOutput = movieOutput else { return }

        if let mainDisplayId = CGMainDisplayID() as? CGDirectDisplayID,
           let input = AVCaptureScreenInput(displayID: mainDisplayId)
        {
            if area != nil {
                input.cropRect = area ?? CGDisplayBounds(CGMainDisplayID())
            }
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        }
        // Add the movie file output
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
        }

        // Start the session
        captureSession.startRunning()

        // Start recording to a file
        movieOutput.startRecording(to: destinationURL, recordingDelegate: self)
    }

    func stopRecording() {
        movieOutput?.stopRecording()
        captureSession?.stopRunning()
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
        // Handle completion of recording
        print("Recording finished: \(outputFileURL.path)")
    }
}
