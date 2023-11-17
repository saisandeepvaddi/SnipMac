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
//                AppDelegate.shared?.hideMainWindow()
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                    ScreenCaptureManager.takeScreenshot()
//                    AppDelegate.shared?.showMainWindow()
//                }
            }

            Button("Capture Area") {
                AppDelegate.shared?.hideMainWindow()
                AppDelegate.shared?.showOverlayWindow()
            }

            Button("Start Recording") {
//                withMainWindowClosed {
                screenRecorder.startRecordingMainScreen()
//                }
//                // Hide the main window before starting the recording
//                AppDelegate.shared?.hideMainWindow()
//
//                // Start screen recording
//
//
//                // Optionally, after a delay, show the main window again
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                    AppDelegate.shared?.showMainWindow()
//                }
            }

            Button("Stop Recording") {
                // Stop screen recording
                screenRecorder.stopRecording()
            }
        }
    }
}

#Preview {
    ContentView()
}
