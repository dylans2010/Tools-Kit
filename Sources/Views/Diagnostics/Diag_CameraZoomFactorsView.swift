import SwiftUI
import AVFoundation
import CoreMedia


struct Diag_CameraZoomFactorsView: View {
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
        .navigationTitle("Camera Zoom Factors")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Max Available Zoom", AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back).map { String(format: "%.1fx", $0.maxAvailableVideoZoomFactor) } ?? "Unavailable"),
            ("Active Format Max Zoom", AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back).map { String(format: "%.1fx", $0.activeFormat.videoMaxZoomFactor) } ?? "Unavailable")
        ]
    }
}
