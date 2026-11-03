import SwiftUI
import AVFoundation


struct Diag_MicAvailableInputsView: View {
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
        .navigationTitle("Mic Available Inputs")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Available Input Count", "\(AVAudioSession.sharedInstance().availableInputs?.count ?? 0)"),
            ("Available Inputs", AVAudioSession.sharedInstance().availableInputs?.map { $0.portName }.joined(separator: ", ") ?? "None"),
            ("Current Input", AVAudioSession.sharedInstance().currentRoute.inputs.first?.portName ?? "None")
        ]
    }
}
