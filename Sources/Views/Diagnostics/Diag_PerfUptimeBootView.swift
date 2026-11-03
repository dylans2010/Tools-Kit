import SwiftUI


struct Diag_PerfUptimeBootView: View {
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
        .navigationTitle("Uptime & Boot Time")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("System Uptime (s)", "\(Int(ProcessInfo.processInfo.systemUptime))"),
            ("Boot Date", "\(Date(timeIntervalSinceNow: -ProcessInfo.processInfo.systemUptime))"),
            ("Thermal State", String(describing: ProcessInfo.processInfo.thermalState))
        ]
    }
}
