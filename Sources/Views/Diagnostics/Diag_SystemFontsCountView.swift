import SwiftUI


struct Diag_SystemFontsCountView: View {
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
        .navigationTitle("Installed Font Count")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Font Family Count", "\(UIFont.familyNames.count)"),
            ("First Families", UIFont.familyNames.sorted().prefix(5).joined(separator: ", "))
        ]
    }
}
