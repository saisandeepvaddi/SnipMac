//
//  SnipMacApp.swift
//  SnipMac
//
//  Created by Sai Sandeep Vaddi on 11/6/23.
//

import SwiftUI

@main
struct SnipMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    appDelegate.mainWindow = NSApplication.shared.windows.first
                }
        }
    }
}
