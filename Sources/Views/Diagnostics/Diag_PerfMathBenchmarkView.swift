import SwiftUI

struct Diag_PerfMathBenchmarkView: View {
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
        .navigationTitle("Math Benchmark")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func run() {
        var total = 0.0
        let start = Date()
        for i in 0..<1_000_000 { total += sin(Double(i) * 0.001) + cos(Double(i) * 0.001) }
        let ms = Date().timeIntervalSince(start) * 1000
        result = String(format: "1,000,000 sin/cos pairs: %.2f ms (sum %.1f)", ms, total)
    }
}
