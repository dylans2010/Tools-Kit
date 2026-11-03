import SwiftUI
import AVFoundation


struct Diag_AudioRouteInputsView: View {
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
        .navigationTitle("Audio Input Routes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Input Count", "\(AVAudioSession.sharedInstance().currentRoute.inputs.count)"),
            ("First Input", AVAudioSession.sharedInstance().currentRoute.inputs.first?.portName ?? "None"),
            ("First Input Type", AVAudioSession.sharedInstance().currentRoute.inputs.first?.portType.rawValue ?? "None"),
            ("All Inputs", AVAudioSession.sharedInstance().currentRoute.inputs.map { $0.portName }.joined(separator: ", "))
        ]
    }
}
