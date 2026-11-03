import SwiftUI


struct Diag_SystemBootTimeView: View {
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
        .navigationTitle("Boot Time")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Boot Date", "\(Date(timeIntervalSinceNow: -ProcessInfo.processInfo.systemUptime))"),
            ("Uptime (days)", "\(ProcessInfo.processInfo.systemUptime / 86400, specifier: "%.1f")"),
            ("Uptime (hours)", "\(ProcessInfo.processInfo.systemUptime / 3600, specifier: "%.1f")")
        ]
    }
}
