import SwiftUI


struct Diag_SystemHostNameView: View {
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
        .navigationTitle("Host & Process Info")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Host Name", ProcessInfo.processInfo.hostName),
            ("Process Name", ProcessInfo.processInfo.processName),
            ("Process ID", "\(ProcessInfo.processInfo.processIdentifier)"),
            ("Argument Count", "\(ProcessInfo.processInfo.arguments.count)")
        ]
    }
}
