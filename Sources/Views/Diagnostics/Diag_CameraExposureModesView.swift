import SwiftUI
import AVFoundation
import CoreMedia


struct Diag_CameraExposureModesView: View {
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
        .navigationTitle("Camera Exposure Modes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Auto Exposure", AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)?.isExposureModeSupported(.autoExpose) == true ? "Supported" : "Not supported"),
            ("Continuous Exposure", AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)?.isExposureModeSupported(.continuousAutoExposure) == true ? "Supported" : "Not supported"),
            ("Locked Exposure", AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)?.isExposureModeSupported(.locked) == true ? "Supported" : "Not supported")
        ]
    }
}
