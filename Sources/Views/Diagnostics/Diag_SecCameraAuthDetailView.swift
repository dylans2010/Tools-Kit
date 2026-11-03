import SwiftUI
import AVFoundation


struct Diag_SecCameraAuthDetailView: View {
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
        .navigationTitle("Camera Auth Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Video Authorization", String(describing: AVCaptureDevice.authorizationStatus(for: .video))),
            ("Audio Authorization", String(describing: AVCaptureDevice.authorizationStatus(for: .audio)))
        ]
    }
}
