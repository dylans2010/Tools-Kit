import SwiftUI
import Metal


struct Diag_PerfMetalLimitsView: View {
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
        .navigationTitle("Metal Limits")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        rows = [
            ("GPU", MTLCreateSystemDefaultDevice()?.name ?? "Unavailable"),
            ("Max Buffer Length", fmtBytes(Int64(MTLCreateSystemDefaultDevice()?.maxBufferLength ?? 0))),
            ("Max Threads Per Group", "\(MTLCreateSystemDefaultDevice()?.maxThreadsPerThreadgroup.width ?? 0)"),
            ("Recommended Working Set", fmtBytes(Int64(MTLCreateSystemDefaultDevice()?.recommendedMaxWorkingSetSize ?? 0)))
        ]
    }
    private func fmtBytes(_ bytes: Int64) -> String {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f.string(fromByteCount: bytes)
    }
}
