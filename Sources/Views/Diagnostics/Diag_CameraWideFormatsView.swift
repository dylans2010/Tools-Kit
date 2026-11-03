import SwiftUI
import AVFoundation
import CoreMedia


struct Diag_CameraWideFormatsView: View {
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
        .navigationTitle("Wide Camera Formats")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Format Count", "\(AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)?.formats.count ?? 0)"),
            ("Max Resolution", AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back).flatMap { $0.formats.last }.map { let d = CMVideoFormatDescriptionGetDimensions($0.formatDescription); return "\(d.width) x \(d.height)" } ?? "Unavailable"),
            ("Max FPS", AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back).flatMap { $0.formats.last }.map { String(format: "%.0f", $0.videoSupportedFrameRateRanges.map { $0.maxFrameRate }.max() ?? 0) } ?? "Unavailable")
        ]
    }
}
