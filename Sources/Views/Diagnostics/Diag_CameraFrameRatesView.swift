import SwiftUI
import AVFoundation
import CoreMedia


struct Diag_CameraFrameRatesView: View {
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
        .navigationTitle("Camera Frame Rates")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Format Count", "\(AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)?.formats.count ?? 0)"),
            ("Max FPS", AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back).flatMap { $0.formats.flatMap { $0.videoSupportedFrameRateRanges }.map { $0.maxFrameRate }.max() }.map { String(format: "%.0f", $0) } ?? "Unavailable"),
            ("Min FPS", AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back).flatMap { $0.formats.flatMap { $0.videoSupportedFrameRateRanges }.map { $0.minFrameRate }.min() }.map { String(format: "%.0f", $0) } ?? "Unavailable")
        ]
    }
}
