import SwiftUI

struct Diag_HapticImpactMediumView: View {
    @State private var lastPlayed = "Not played yet"

    var body: some View {
        Form {
            Section("Haptic Test") {
                LabeledContent("Last Played") { Text(lastPlayed) }
                Text("Haptics require a physical device with a Taptic Engine; they do not fire in the simulator.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section {
                Button("Play Medium Impact") {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    lastPlayed = "Medium impact"
                }
            }
        }
        .navigationTitle("Impact Medium")
        .navigationBarTitleDisplayMode(.inline)
    }
}
