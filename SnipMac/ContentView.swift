//
//  ContentView.swift
//  SnipMac
//
//  Created by Sai Sandeep Vaddi on 11/6/23.
//

import Foundation
import SwiftUI

struct ContentView: View {
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

            Button("Start Recording") {}
        }
    }
}

#Preview {
    ContentView()
}
