import SwiftUI
import AVFoundation


struct Diag_SecMicAuthDetailView: View {
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
        .navigationTitle("Microphone Auth Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Audio Authorization", String(describing: AVCaptureDevice.authorizationStatus(for: .audio))),
            ("Input Available", AVAudioSession.sharedInstance().isInputAvailable ? "Yes" : "No")
        ]
    }
}
