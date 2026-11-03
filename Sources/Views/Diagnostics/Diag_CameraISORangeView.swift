import SwiftUI
import AVFoundation
import CoreMedia


struct Diag_CameraISORangeView: View {
    @State private var rows: [(String, String)] = []

    var body: some View {
        Form {
            Section("Results") {
                ForEach(rows, id: \.0) { row in
                    LabeledContent(row.0) { Text(row.1).font(.caption) }
                }
            }

            Section {
                Button { load() } label: {
                    HStack { Image(systemName: "arrow.clockwise"); Text("Refresh") }
                }
            }
        }
        .navigationTitle("Camera ISO Range")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Min ISO", AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back).map { String(format: "%.0f", $0.activeFormat.minISO) } ?? "Unavailable"),
            ("Max ISO", AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back).map { String(format: "%.0f", $0.activeFormat.maxISO) } ?? "Unavailable"),
            ("Max Zoom (format)", AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back).map { String(format: "%.1fx", $0.activeFormat.videoMaxZoomFactor) } ?? "Unavailable"),
            ("Field Of View", AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back).map { String(format: "%.1f deg", $0.activeFormat.videoFieldOfView) } ?? "Unavailable")
        ]
    }
}
