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
                ScreenCaptureManager.takeScreenshot()
            }
            Button("Start Recording") {}
        }
    }
}

#Preview {
    ContentView()
}
