import SwiftUI
import AVFoundation
import CoreMedia


struct Diag_CameraFocusModesView: View {
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
        .navigationTitle("Camera Focus Modes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Auto Focus", AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)?.isFocusModeSupported(.autoFocus) == true ? "Supported" : "Not supported"),
            ("Continuous AF", AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)?.isFocusModeSupported(.continuousAutoFocus) == true ? "Supported" : "Not supported"),
            ("Locked Focus", AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)?.isFocusModeSupported(.locked) == true ? "Supported" : "Not supported")
        ]
    }
}
