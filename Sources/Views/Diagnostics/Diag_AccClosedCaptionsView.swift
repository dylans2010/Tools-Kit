import SwiftUI


struct Diag_AccClosedCaptionsView: View {
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
        .navigationTitle("Closed Captions Status")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Closed Captioning", UIAccessibility.isClosedCaptioningEnabled ? "On" : "Off"),
            ("Mono Audio", UIAccessibility.isMonoAudioEnabled ? "On" : "Off")
        ]
    }
}
