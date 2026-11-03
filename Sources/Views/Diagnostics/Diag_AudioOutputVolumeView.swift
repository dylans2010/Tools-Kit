import SwiftUI
import AVFoundation


struct Diag_AudioOutputVolumeView: View {
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
        .navigationTitle("Audio Output Volume")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Output Volume", "\(Int(AVAudioSession.sharedInstance().outputVolume * 100))%"),
            ("Other Audio Playing", AVAudioSession.sharedInstance().isOtherAudioPlaying ? "Yes" : "No"),
            ("Input Available", AVAudioSession.sharedInstance().isInputAvailable ? "Yes" : "No")
        ]
    }
}
