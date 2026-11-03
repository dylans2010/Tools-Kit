import SwiftUI


struct Diag_AccAssistiveTouchView: View {
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
        .navigationTitle("AssistiveTouch Status")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("AssistiveTouch", UIAccessibility.isAssistiveTouchRunning ? "Running" : "Not running"),
            ("VoiceOver", UIAccessibility.isVoiceOverRunning ? "Running" : "Not running")
        ]
    }
}
