import SwiftUI


struct Diag_AccSpeakSelectionView: View {
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
        .navigationTitle("Speak Selection Status")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Speak Selection", UIAccessibility.isSpeakSelectionEnabled ? "On" : "Off"),
            ("Speak Screen", UIAccessibility.isSpeakScreenEnabled ? "On" : "Off")
        ]
    }
}
