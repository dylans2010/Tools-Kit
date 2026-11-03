import SwiftUI

struct Diag_HapticNotificationFeedbackView: View {
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
                Button("Success") { UINotificationFeedbackGenerator().notificationOccurred(.success); lastPlayed = "Success" }
                Button("Warning") { UINotificationFeedbackGenerator().notificationOccurred(.warning); lastPlayed = "Warning" }
                Button("Error") { UINotificationFeedbackGenerator().notificationOccurred(.error); lastPlayed = "Error" }
            }
        }
        .navigationTitle("Notification Haptics")
        .navigationBarTitleDisplayMode(.inline)
    }
}
