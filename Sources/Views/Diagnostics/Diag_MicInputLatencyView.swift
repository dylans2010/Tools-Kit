import SwiftUI
import AVFoundation


struct Diag_MicInputLatencyView: View {
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
        .navigationTitle("Mic Input Latency")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Input Latency (ms)", "\(AVAudioSession.sharedInstance().inputLatency * 1000, specifier: "%.1f")"),
            ("I/O Buffer (ms)", "\(AVAudioSession.sharedInstance().ioBufferDuration * 1000, specifier: "%.1f")"),
            ("Sample Rate", "\(Int(AVAudioSession.sharedInstance().sampleRate)) Hz")
        ]
    }
}
