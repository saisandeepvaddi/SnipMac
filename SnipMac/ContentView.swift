import AppKit
import SwiftUI

struct ContentView: View {
    @AppStorage("includesMicrophone") private var includesMicrophone = false
    @AppStorage("recordingCountdown") private var recordingCountdown = 3
    @AppStorage("captureDirectory") private var captureDirectory = ""

    var body: some View {
        Form {
            Section("Captures") {
                LabeledContent("Save to") {
                    HStack {
                        Text(displayedCaptureDirectory)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Button("Choose…", action: chooseCaptureDirectory)
                    }
                }
                LabeledContent("Screenshots", value: "PNG · autosave + clipboard")
                LabeledContent("Recordings", value: "MP4 · autosave")
            }

            Section("Recording") {
                Toggle("Include microphone audio", isOn: $includesMicrophone)
                Picker("Countdown", selection: $recordingCountdown) {
                    Text("None").tag(0)
                    Text("3 seconds").tag(3)
                    Text("5 seconds").tag(5)
                }
                Text("Microphone permission is requested only when this option is enabled and a recording starts.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Global Shortcuts") {
                shortcutRow("Capture Display", action: .displayScreenshot)
                shortcutRow("Capture Region", action: .regionScreenshot)
                shortcutRow("Capture Window", action: .windowScreenshot)
                shortcutRow("Record Display", action: .displayRecording)
                shortcutRow("Record Region", action: .regionRecording)
            }

            Section("Permissions") {
                HStack {
                    Button("Screen Recording Settings") {
                        NSWorkspace.shared.open(.screenRecordingSettings)
                    }
                    Button("Microphone Settings") {
                        NSWorkspace.shared.open(.microphoneSettings)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 460)
    }

    private var displayedCaptureDirectory: String {
        captureDirectory.isEmpty ? "Pictures/SnipMac" : captureDirectory
    }

    private func shortcutRow(_ title: String, action: GlobalShortcutManager.Action) -> some View {
        LabeledContent(title) {
            Text(action.displayName)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    private func chooseCaptureDirectory() {
        let panel = NSOpenPanel()
        panel.message = "Choose where SnipMac saves captures"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            captureDirectory = url.path
        }
    }
}
