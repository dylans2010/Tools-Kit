import SwiftUI
import AVFoundation
import CoreMedia


struct Diag_CameraDeviceListView: View {
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
        .navigationTitle("Camera Device List")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Device Count", "\(AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInTelephotoCamera, .builtInUltraWideCamera, .builtInTrueDepthCamera, .builtInLiDARDepthCamera], mediaType: .video, position: .unspecified).devices.count)"),
            ("Devices", AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInTelephotoCamera, .builtInUltraWideCamera, .builtInTrueDepthCamera, .builtInLiDARDepthCamera], mediaType: .video, position: .unspecified).devices.map { $0.localizedName }.joined(separator: ", "))
        ]
    }
}
