import SwiftUI


struct Diag_AccSwitchControlView: View {
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
        .navigationTitle("Switch Control Status")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Switch Control", UIAccessibility.isSwitchControlRunning ? "Running" : "Not running"),
            ("VoiceOver", UIAccessibility.isVoiceOverRunning ? "Running" : "Not running"),
            ("Guided Access", UIAccessibility.isGuidedAccessEnabled ? "Enabled" : "Disabled")
        ]
    }
}
