import SwiftUI
import AVFoundation


struct Diag_AudioCategoryModeView: View {
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
        .navigationTitle("Audio Category & Mode")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Category", AVAudioSession.sharedInstance().category.rawValue),
            ("Mode", AVAudioSession.sharedInstance().mode.rawValue),
            ("Allow Bluetooth", AVAudioSession.sharedInstance().categoryOptions.contains(.allowBluetooth) ? "Yes" : "No"),
            ("Default To Speaker", AVAudioSession.sharedInstance().categoryOptions.contains(.defaultToSpeaker) ? "Yes" : "No")
        ]
    }
}
