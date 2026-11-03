import SwiftUI
import AVFoundation


struct Diag_MicDataSourcesView: View {
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
        .navigationTitle("Mic Data Sources")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Input Count", "\(AVAudioSession.sharedInstance().currentRoute.inputs.count)"),
            ("First Input", AVAudioSession.sharedInstance().currentRoute.inputs.first?.portName ?? "None"),
            ("Data Sources", AVAudioSession.sharedInstance().currentRoute.inputs.first?.dataSources?.map { $0.dataSourceName ?? "Unnamed" }.joined(separator: ", ") ?? "None")
        ]
    }
}
