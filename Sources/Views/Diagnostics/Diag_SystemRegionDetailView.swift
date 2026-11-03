import SwiftUI


struct Diag_SystemRegionDetailView: View {
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
        .navigationTitle("Region Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Region Code", Locale.current.region?.identifier ?? "Unknown"),
            ("Currency Code", Locale.current.currency?.identifier ?? "Unknown"),
            ("Measurement System", Locale.current.measurementSystem == .metric ? "Metric" : Locale.current.measurementSystem == .us ? "US" : "UK"),
            ("Calendar", Calendar.current.identifier.debugDescription)
        ]
    }
}
