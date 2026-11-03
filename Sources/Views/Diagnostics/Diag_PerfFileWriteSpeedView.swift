import SwiftUI

struct Diag_PerfFileWriteSpeedView: View {
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
        .navigationTitle("File Write Speed")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func run() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("diag-write-test.bin")
        let data = Data(repeating: 0, count: 1024 * 1024)
        let start = Date()
        try? data.write(to: url)
        let elapsed = Date().timeIntervalSince(start)
        try? FileManager.default.removeItem(at: url)
        result = String(format: "%.1f MB/s (1 MB in %.3f s)", elapsed > 0 ? 1 / elapsed : 0, elapsed)
    }
}
