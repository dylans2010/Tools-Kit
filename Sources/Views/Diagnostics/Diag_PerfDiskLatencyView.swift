import SwiftUI

struct Diag_PerfDiskLatencyView: View {
    @State private var result = "Not run yet"

    var body: some View {
        Form {
            Section("Benchmark") {
                Text(result).font(.subheadline).monospacedDigit()
            }
            Section {
                Button("Run Benchmark") { run() }
            }
            Section {
                Text("Runs on-device in real time; nothing here is a stored or simulated result.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Disk Write Latency")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func run() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("diag-latency-test.txt")
        let data = Data("diagnostics".utf8)
        let start = Date()
        for _ in 0..<10 { try? data.write(to: url) }
        let ms = Date().timeIntervalSince(start) * 1000 / 10
        try? FileManager.default.removeItem(at: url)
        result = String(format: "%.2f ms per write", ms)
    }
}
