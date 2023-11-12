//
//  ContentView.swift
//  SnipMac
//
//  Created by Sai Sandeep Vaddi on 11/6/23.
//

import Foundation
import SwiftUI

struct ContentView: View {
    @State private var selectedRect: CGRect = .zero
    @State private var isSelecting: Bool = false

    var body: some View {
        VStack {
            Button("Take Screenshot") {
                self.isSelecting = false
                ScreenCaptureManager.takeScreenshot()
            }

            Button("Capture Area") {
                AppDelegate.shared?.showOverlayWindow()
            }

            Button("Start Recording") {}
        }
    }
}

#Preview {
    ContentView()
}
