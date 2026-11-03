import SwiftUI
import AVFoundation


struct Diag_AudioSessionOptionsView: View {
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
        .navigationTitle("Audio Session Options")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Is Recording", AVAudioSession.sharedInstance().isInputAvailable ? "Input available" : "No input"),
            ("Category", AVAudioSession.sharedInstance().category.rawValue),
            ("Mode", AVAudioSession.sharedInstance().mode.rawValue),
            ("Output Volume", "\(Int(AVAudioSession.sharedInstance().outputVolume * 100))%")
        ]
    }
}
