//
//  ScreenRecorder.swift
//  SnipMac
//
//  Created by Sai Sandeep Vaddi on 11/16/23.
//

import AVFoundation
import Foundation

class ScreenRecorder: NSObject, AVCaptureFileOutputRecordingDelegate {
    private var captureSession: AVCaptureSession?
    private var movieOutput: AVCaptureMovieFileOutput?
    private var destinationURL: URL

    override init() {
        captureSession = AVCaptureSession()
        movieOutput = AVCaptureMovieFileOutput()

        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        let timestamp = dateFormatter.string(from: Date())
        destinationURL = desktopURL.appendingPathComponent("SnipMacScreenRecording \(timestamp).mp4")
        super.init()
    }

    func startRecordingMainScreen() {
        guard let captureSession = captureSession, let movieOutput = movieOutput else { return }

        if let mainDisplayId = CGMainDisplayID() as? CGDirectDisplayID,
           let input = AVCaptureScreenInput(displayID: mainDisplayId)
        {
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
