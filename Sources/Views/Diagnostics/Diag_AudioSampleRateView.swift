import SwiftUI
import AVFoundation


struct Diag_AudioSampleRateView: View {
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
        .navigationTitle("Audio Sample Rate")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Sample Rate", "\(Int(AVAudioSession.sharedInstance().sampleRate)) Hz"),
            ("I/O Buffer Duration", String(format: "%.4f s", AVAudioSession.sharedInstance().ioBufferDuration)),
            ("Input Latency", String(format: "%.4f s", AVAudioSession.sharedInstance().inputLatency)),
            ("Output Latency", String(format: "%.4f s", AVAudioSession.sharedInstance().outputLatency))
        ]
    }
}
