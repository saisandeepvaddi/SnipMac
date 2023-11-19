//
//  ContentView.swift
//  SnipMac
//
//  Created by Sai Sandeep Vaddi on 11/6/23.
//

import Foundation
import SwiftUI

struct ContentView: View {
    let screenRecorder = ScreenRecorder.shared
    let overlayWindowManager = OverlayWindowManager.shared
    var body: some View {
        VStack {
            Button("Take Screenshot") {
                withMainWindowClosed {
                    ScreenCaptureManager.takeScreenshot()
                }
            }

            Button("Capture Area") {
                overlayWindowManager.hideMainWindow()
                overlayWindowManager.showOverlayWindow(captureType: .screenshot)
            }

            Button("Start Recording whole screen") {
                screenRecorder.startRecordingMainScreen()
            }

            Button("Start Recording area") {
                overlayWindowManager.showOverlayWindow(captureType: .screenRecord)
            }

            Button("Stop Recording") {
                screenRecorder.stopRecording()
            }
        }
    }
}
