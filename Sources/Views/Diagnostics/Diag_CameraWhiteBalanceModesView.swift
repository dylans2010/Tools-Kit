import SwiftUI
import AVFoundation
import CoreMedia


struct Diag_CameraWhiteBalanceModesView: View {
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
        .navigationTitle("Camera White Balance")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Auto White Balance", AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)?.isWhiteBalanceModeSupported(.autoWhiteBalance) == true ? "Supported" : "Not supported"),
            ("Continuous WB", AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)?.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) == true ? "Supported" : "Not supported"),
            ("Locked WB", AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)?.isWhiteBalanceModeSupported(.locked) == true ? "Supported" : "Not supported")
        ]
    }
}
