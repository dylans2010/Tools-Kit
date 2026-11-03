import SwiftUI

struct Diag_PerfStringBenchmarkView: View {
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
        .navigationTitle("String Sort Benchmark")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func run() {
        var items = (0..<10000).map { "item-\($0)-diagnostics" }
        let start = Date()
        items.sort()
        let ms = Date().timeIntervalSince(start) * 1000
        result = String(format: "Sorting 10,000 strings: %.2f ms", ms)
    }
}
