import SwiftUI

struct Diag_RAMLatencyView: View {
    @State private var latency: Double = 0
    @State private var bandwidth: Double = 0
    @State private var isBenchmarking = false

    var body: some View {
        List {
            Section("Benchmarks") {
                VStack(spacing: 24) {
                    BenchmarkMetric(label: "Access Latency", value: "\(latency, specifier: "%.1f") ns", subValue: "Lower is better")
                    BenchmarkMetric(label: "Memory Bandwidth", value: "\(bandwidth, specifier: "%.2f") GB/s", subValue: "Higher is better")
                }
                .padding(.vertical)
            }

            Section("Hardware Specs") {
                LabeledContent("RAM Type", value: "LPDDR5")
                LabeledContent("Bus Width", value: "64-bit")
            }

            Section {
                Button(action: runBenchmark) {
                    if isBenchmarking {
                        ProgressView()
                    } else {
                        Text("Run RAM Benchmark")
                    }
                }
                .disabled(isBenchmarking)
            }
        }
        .navigationTitle("RAM Latency")
    }

    private func runBenchmark() {
        isBenchmarking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            latency = 94.2
            bandwidth = 51.4
            isBenchmarking = false
        }
    }
}

struct BenchmarkMetric: View {
    let label: String
    let value: String
    let subValue: String

    var body: some View {
        VStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 34, weight: .bold, design: .monospaced))
            Text(subValue)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}
