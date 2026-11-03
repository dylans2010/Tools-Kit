import SwiftUI


struct Diag_SystemLanguageListView: View {
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
        .navigationTitle("Preferred Languages")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("First Language", Locale.preferredLanguages.first ?? "Unknown"),
            ("Language Count", "\(Locale.preferredLanguages.count)"),
            ("All Languages", Locale.preferredLanguages.joined(separator: ", ")),
            ("Current Locale", Locale.current.identifier)
        ]
    }
}
