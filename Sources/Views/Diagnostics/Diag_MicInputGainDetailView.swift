import SwiftUI
import AVFoundation


struct Diag_MicInputGainDetailView: View {
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
        .navigationTitle("Mic Input Gain Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Input Gain", String(format: "%.2f", AVAudioSession.sharedInstance().inputGain)),
            ("Gain Settable", AVAudioSession.sharedInstance().isInputGainSettable ? "Yes" : "No"),
            ("Input Channels", "\(AVAudioSession.sharedInstance().inputNumberOfChannels)")
        ]
    }
}
