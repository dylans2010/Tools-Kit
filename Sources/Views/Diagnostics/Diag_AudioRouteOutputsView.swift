import SwiftUI
import AVFoundation


struct Diag_AudioRouteOutputsView: View {
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
        .navigationTitle("Audio Output Routes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Output Count", "\(AVAudioSession.sharedInstance().currentRoute.outputs.count)"),
            ("First Output", AVAudioSession.sharedInstance().currentRoute.outputs.first?.portName ?? "None"),
            ("First Output Type", AVAudioSession.sharedInstance().currentRoute.outputs.first?.portType.rawValue ?? "None"),
            ("All Outputs", AVAudioSession.sharedInstance().currentRoute.outputs.map { $0.portName }.joined(separator: ", "))
        ]
    }
}
