import SwiftUI

struct ScreenRecordingOverlayView: View {
    @State private var selectedRect = CGRect.zero
    @State private var isSelecting = false
    var captureType: CaptureType = .screenshot
    var screenRecorder: ScreenRecorder = .init()

    var drag: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                let adjustedStartLocation = CGPoint(x: value.startLocation.x,
                                                    y: value.startLocation.y)
                let adjustedLocation = CGPoint(x: value.location.x,
                                               y: value.location.y)

                let origin = CGPoint(x: min(adjustedStartLocation.x, adjustedLocation.x),
                                     y: min(adjustedStartLocation.y, adjustedLocation.y))
                let size = CGSize(width: abs(adjustedLocation.x - adjustedStartLocation.x),
                                  height: abs(adjustedLocation.y - adjustedStartLocation.y))

                selectedRect = CGRect(origin: origin, size: size)
                isSelecting = true
            }
            .onEnded { _ in
                if captureType == .screenshot {
                    isSelecting = false
                    AppDelegate.shared?.hideOverlayWindow()
                    withMainWindowClosed {
                        ScreenCaptureManager.takeScreenshot(of: selectedRect)
                    }
                } else {
                    isSelecting = false
                    AppDelegate.shared?.hideOverlayWindow()
                    screenRecorder.startRecording(of: selectedRect)
                }
            }
    }

    var body: some View {
        GeometryReader { geometry in
            Group {
                if isSelecting {
                    // Blue border for the selected area
                    Rectangle()
                        .stroke(Color.white, lineWidth: 2)
                        .background(Color.black.opacity(0.2))
                        .frame(width: selectedRect.width, height: selectedRect.height)
                        .offset(x: selectedRect.minX,
                                y: selectedRect.minY)
                }

                Rectangle()
                    .fill(Color.clear)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .contentShape(Rectangle())
                    .gesture(
                        drag
                    )
            }
        }
    }
}
