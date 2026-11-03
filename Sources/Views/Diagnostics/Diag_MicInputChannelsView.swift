import SwiftUI
import AVFoundation


struct Diag_MicInputChannelsView: View {
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
        .navigationTitle("Mic Input Channels")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Input Channels", "\(AVAudioSession.sharedInstance().inputNumberOfChannels)"),
            ("Input Available", AVAudioSession.sharedInstance().isInputAvailable ? "Yes" : "No"),
            ("Input Gain", "\(AVAudioSession.sharedInstance().inputGain, specifier: "%.2f")")
        ]
    }
}
