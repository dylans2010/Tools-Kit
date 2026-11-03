import SwiftUI
import AVFoundation


struct Diag_AudioAirPlayRouteView: View {
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
        .navigationTitle("AirPlay Route")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("AirPlay Active", AVAudioSession.sharedInstance().currentRoute.outputs.contains { $0.portType == .airPlay } ? "Yes" : "No"),
            ("Output Ports", "\(AVAudioSession.sharedInstance().currentRoute.outputs.count)"),
            ("Output Types", AVAudioSession.sharedInstance().currentRoute.outputs.map { $0.portType.rawValue }.joined(separator: ", "))
        ]
    }
}
