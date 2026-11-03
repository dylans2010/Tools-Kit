import SwiftUI


struct Diag_AccMonoAudioView: View {
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
        .navigationTitle("Mono Audio Status")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Mono Audio", UIAccessibility.isMonoAudioEnabled ? "On" : "Off"),
            ("Closed Captioning", UIAccessibility.isClosedCaptioningEnabled ? "On" : "Off")
        ]
    }
}
