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
            ("I/O Buffer Duration", "\(AVAudioSession.sharedInstance().ioBufferDuration, specifier: "%.4f") s"),
            ("Input Latency", "\(AVAudioSession.sharedInstance().inputLatency, specifier: "%.4f") s"),
            ("Output Latency", "\(AVAudioSession.sharedInstance().outputLatency, specifier: "%.4f") s")
        ]
    }
}
