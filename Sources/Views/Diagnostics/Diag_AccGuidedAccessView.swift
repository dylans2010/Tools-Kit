import SwiftUI


struct Diag_AccGuidedAccessView: View {
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
        .navigationTitle("Guided Access Status")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Guided Access", UIAccessibility.isGuidedAccessEnabled ? "Enabled" : "Disabled"),
            ("VoiceOver", UIAccessibility.isVoiceOverRunning ? "Running" : "Not running")
        ]
    }
}
