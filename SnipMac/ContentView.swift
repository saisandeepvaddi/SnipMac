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
        VStack(alignment: .leading) {
            Button("Take Screenshot") {
                withMenubarClosed {
                    ScreenCaptureManager.takeScreenshot()
                }
            }

            Button("Capture Area") {
                withMenubarClosed {
                    overlayWindowManager.showOverlayWindow(captureType: .screenshot)
                }
            }

            Button("Start Recording whole screen") {
                withMenubarClosed {
                    screenRecorder.startRecordingMainScreen()
                }
            }

            Button("Start Recording area") {
                withMenubarClosed {
                    overlayWindowManager.showOverlayWindow(captureType: .screenRecord)
                }
            }

            Button("Stop Recording") {
                withMenubarClosed {
                    screenRecorder.stopRecording()
                }
            }

        }.padding()
    }
}
