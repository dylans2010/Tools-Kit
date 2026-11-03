import SwiftUI
import AVFoundation
import CoreMedia


struct Diag_CameraFlashModesView: View {
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
        .navigationTitle("Camera Flash Modes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Has Flash", AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)?.hasFlash == true ? "Yes" : "No"),
            ("Has Torch", AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)?.hasTorch == true ? "Yes" : "No"),
            ("Flash Auto Supported", AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)?.isFlashModeSupported(.auto) == true ? "Yes" : "No"),
            ("Low Light Boost", AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)?.isLowLightBoostSupported == true ? "Supported" : "Not supported")
        ]
    }
}
