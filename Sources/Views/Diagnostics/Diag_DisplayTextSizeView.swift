import SwiftUI


struct Diag_DisplayTextSizeView: View {
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
        .navigationTitle("Text Size Setting")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Content Size Category", UIApplication.shared.preferredContentSizeCategory.rawValue),
            ("Bold Text", UIAccessibility.isBoldTextEnabled ? "On" : "Off"),
            ("Larger Text Available", "Yes (Settings > Accessibility > Display)")
        ]
    }
}
