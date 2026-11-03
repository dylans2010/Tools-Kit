import SwiftUI


struct Diag_SystemTimezoneDetailView: View {
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
        .navigationTitle("Timezone Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Timezone", TimeZone.current.identifier),
            ("Abbreviation", TimeZone.current.abbreviation() ?? "Unknown"),
            ("Seconds From GMT", "\(TimeZone.current.secondsFromGMT())"),
            ("Daylight Saving Now", TimeZone.current.isDaylightSavingTime() ? "Yes" : "No")
        ]
    }
}
