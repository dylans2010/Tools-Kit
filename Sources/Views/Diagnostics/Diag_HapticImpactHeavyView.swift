import SwiftUI

struct Diag_HapticImpactHeavyView: View {
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
                Button("Play Heavy Impact") {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    lastPlayed = "Heavy impact"
                }
            }
        }
        .navigationTitle("Impact Heavy")
        .navigationBarTitleDisplayMode(.inline)
    }
}
