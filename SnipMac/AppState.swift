//
//  State.swift
//  SnipMac
//
//  Created by Sai Sandeep Vaddi on 11/18/23.
//

import Foundation

class AppState: ObservableObject {
    @Published var showOverlay = false
    @Published var recorder: ScreenRecorder = .init()
}
