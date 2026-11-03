import SwiftUI
import AVFoundation
import CoreMedia


struct Diag_CameraTrueDepthDetailView: View {
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
        .navigationTitle("TrueDepth Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("TrueDepth Present", AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTrueDepthCamera], mediaType: .video, position: .front).devices.isEmpty ? "No" : "Yes"),
            ("Front Wide HDR", AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)?.activeFormat.isVideoHDRSupported == true ? "Supported" : "Not supported"),
            ("Front Wide Flash", AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)?.hasFlash == true ? "Yes (Retina Flash)" : "No")
        ]
    }
}
