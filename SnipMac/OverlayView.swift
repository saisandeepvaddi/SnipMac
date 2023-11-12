import SwiftUI

struct OverlayView: View {
    @State private var selectedRect = CGRect.zero
    @State private var isSelecting = false
    var body: some View {
        GeometryReader { geometry in
            Group {
                if isSelecting {
//                    // Top rectangle
//                    Rectangle()
//                        .fill(Color.black.opacity(0.5))
//                        .frame(width: geometry.size.width, height: selectedRect.minY)
//
//                    // Bottom rectangle
//                    Rectangle()
//                        .fill(Color.black.opacity(0.5))
//                        .frame(width: geometry.size.width, height: geometry.size.height - selectedRect.maxY)
//                        .offset(y: selectedRect.maxY)
//
//                    // Left rectangle
//                    Rectangle()
//                        .fill(Color.black.opacity(0.5))
//                        .frame(width: selectedRect.minX, height: selectedRect.height)
//                        .offset(y: selectedRect.minY)
//
//                    // Right rectangle
//                    Rectangle()
//                        .fill(Color.black.opacity(0.5))
//                        .frame(width: geometry.size.width - selectedRect.maxX, height: selectedRect.height)
//                        .offset(x: selectedRect.maxX, y: selectedRect.minY)

                    // Blue border for the selected area
                    Rectangle()
                        .stroke(Color.white, lineWidth: 2)
                        .background(Color.black.opacity(0.8))
                        .frame(width: selectedRect.width, height: selectedRect.height)
                        .offset(x: selectedRect.minX,
                                y: selectedRect.minY)
                }

                Rectangle()
                    .fill(Color.clear)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .contentShape(Rectangle())
                    .gesture(
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
                                print(selectedRect)
                                isSelecting = true
                            }
                            .onEnded { _ in
                                isSelecting = false
                                AppDelegate.shared?.hideOverlayWindow()
                                ScreenCaptureManager.takeScreenshot(of: selectedRect)
                            }
                    )
            }
        }
    }
}
