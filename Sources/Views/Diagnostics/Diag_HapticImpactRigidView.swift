import SwiftUI

struct Diag_HapticImpactRigidView: View {
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
                Button("Play Rigid Impact") {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    lastPlayed = "Rigid impact"
                }
            }
        }
        .navigationTitle("Impact Rigid")
        .navigationBarTitleDisplayMode(.inline)
    }
}
