//
//  ScreenRecorder.swift
//  SnipMac
//
//  Created by Sai Sandeep Vaddi on 11/19/23.
//

import AVFoundation
import Foundation
import ScreenCaptureKit

class ScreenRecorder {
    var isRunning = false
    // 1. Content Filter
    private(set) var availableDisplays = [SCDisplay]()
    private(set) var availableWindows = [SCWindow]()
    private var availableApps = [SCRunningApplication]()
    
    private let assetWriter: AVAssetWriter?
    
    var selectedDisplay: SCDisplay?
    
    var selectedWindow: SCWindow?
    private var scaleFactor: Int { Int(NSScreen.main?.backingScaleFactor ?? 2) }

    private func filterWindows(_ windows: [SCWindow]) -> [SCWindow] {
        windows
            // Sort the windows by app name.
            .sorted { $0.owningApplication?.applicationName ?? "" < $1.owningApplication?.applicationName ?? "" }
            // Remove windows that don't have an associated .app bundle.
            .filter { $0.owningApplication != nil && $0.owningApplication?.applicationName != "" }
            // Remove this app's window from the list.
            .filter { $0.owningApplication?.bundleIdentifier != Bundle.main.bundleIdentifier }
    }

    private func getAvailableContent() async {
        do {
            // Retrieve the available screen content to capture.
            let availableContent = try await SCShareableContent.excludingDesktopWindows(false,
                                                                                        onScreenWindowsOnly: true)
            availableDisplays = availableContent.displays

            let windows = filterWindows(availableContent.windows)
            if windows != availableWindows {
                availableWindows = windows
            }
            availableApps = availableContent.applications

            if selectedDisplay == nil {
                selectedDisplay = availableDisplays.first
            }
            if selectedWindow == nil {
                selectedWindow = availableWindows.first
            }
        } catch {
            print("Failed to get the shareable content: \(error.localizedDescription)")
        }
    }
    
    func getNewOutputFileURL() -> URL {
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "SnipMacScreenRecording \(timestamp).mp4"
        return desktopURL.appendingPathComponent(filename)
    }

    // 2. Create Stream Config
    
    private var streamConfiguration: SCStreamConfiguration {
        let streamConfig = SCStreamConfiguration()
        
        // Configure audio capture.
        streamConfig.capturesAudio = false
        streamConfig.excludesCurrentProcessAudio = true
        
        // Configure the display content width and height.
        if let display = selectedDisplay {
            streamConfig.width = display.width * scaleFactor
            streamConfig.height = display.height * scaleFactor
        }
        
        // Configure the window content width and height.
        if let window = selectedWindow {
            streamConfig.width = Int(window.frame.width) * 2
            streamConfig.height = Int(window.frame.height) * 2
        }
        
        // Set the capture interval at 60 fps.
        streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        
        // Increase the depth of the frame queue to ensure high fps at the expense of increasing
        // the memory footprint of WindowServer.
        streamConfig.queueDepth = 5
        
        return streamConfig
    }

    // 3. Start Capture Session
    func startRecordingMainScreen() async {
        await startRecording()
    }
    
    func startRecording() async {
        guard CGPreflightScreenCaptureAccess() else {
            print("No screen capture permissions")
        }
        
        guard !isRunning else { return }
    }
    
    func stopRecording() {
        guard isRunning else { return }
    }
    // 4. Process the Output
    // 5. Process a video sample buffer
    // 6. Process an audio sample buffer
}
