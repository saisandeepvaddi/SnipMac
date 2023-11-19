//
//  SnipMacApp.swift
//  SnipMac
//
//  Created by Sai Sandeep Vaddi on 11/6/23.
//

import SwiftUI

@main
struct SnipMacApp: App {
//    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
//    @StateObject var appState = AppState()
    var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    OverlayWindowManager.shared.mainWindow = NSApplication.shared.windows.first
                }
        }
    }
}
