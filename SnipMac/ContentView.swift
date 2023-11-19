//
//  ContentView.swift
//  SnipMac
//
//  Created by Sai Sandeep Vaddi on 11/6/23.
//

import Foundation
import SwiftUI

struct ContentView: View {
    let screenRecorder = ScreenRecorder()
    var body: some View {
        VStack {
            Button("Take Screenshot") {
                withMainWindowClosed {
                    ScreenCaptureManager.takeScreenshot()
                }
            }

            Button("Capture Area") {
                AppDelegate.shared?.hideMainWindow()
                AppDelegate.shared?.showOverlayWindow(captureType: .screenshot)
            }

            Button("Start Recording whole screen") {
                screenRecorder.startRecordingMainScreen()
            }

            Button("Start Recording area") {
                AppDelegate.shared?.showOverlayWindow(captureType: .screenRecord, screenRecorder: screenRecorder)
            }

            Button("Stop Recording") {
                // Stop screen recording
                screenRecorder.stopRecording()
            }
        }
    }
}
