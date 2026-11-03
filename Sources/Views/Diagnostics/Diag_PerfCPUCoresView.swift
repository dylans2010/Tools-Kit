import SwiftUI


struct Diag_PerfCPUCoresView: View {
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
        .navigationTitle("CPU Cores Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("Processor Count", "\(ProcessInfo.processInfo.processorCount)"),
            ("Active Processors", "\(ProcessInfo.processInfo.activeProcessorCount)"),
            ("Physical Memory", fmtBytes(Int64(ProcessInfo.processInfo.physicalMemory)))
        ]
    }
    private func fmtBytes(_ bytes: Int64) -> String {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f.string(fromByteCount: bytes)
    }
}
