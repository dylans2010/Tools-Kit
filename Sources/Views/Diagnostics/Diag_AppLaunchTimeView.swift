import SwiftUI

struct Diag_AppLaunchTimeView: View {
    @State private var coldLaunchTime: Double = 0
    @State private var warmLaunchTime: Double = 0
    @State private var isTesting = false
    @State private var iterations: Int = 0
    @State private var results: [Double] = []

    var body: some View {
        Form {
            Section("Launch Performance") {
                VStack(spacing: 12) {
                    Image(systemName: "timer")
                        .font(.system(size: 44))
                        .foregroundStyle(.orange)
                    if results.isEmpty {
                        Text("Tap Start to measure")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        let avg = results.reduce(0, +) / Double(results.count)
                        Text(String(format: "%.1f ms", avg))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("Average Operation Time")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Results") {
                LabeledContent("Tests Run") { Text("\(iterations)").monospacedDigit() }
                LabeledContent("Min Time") {
                    Text(results.isEmpty ? "—" : String(format: "%.1f ms", results.min() ?? 0))
                        .monospacedDigit()
                }
                LabeledContent("Max Time") {
                    Text(results.isEmpty ? "—" : String(format: "%.1f ms", results.max() ?? 0))
                        .monospacedDigit()
                }
                LabeledContent("Process Uptime") {
                    Text(String(format: "%.1f s", ProcessInfo.processInfo.systemUptime))
                        .monospacedDigit()
                }
            }

            Section("System") {
                LabeledContent("Active Processors") {
                    Text("\(ProcessInfo.processInfo.activeProcessorCount)")
                }
                LabeledContent("Physical Memory") {
                    let mem = ProcessInfo.processInfo.physicalMemory
                    Text(ByteCountFormatter.string(fromByteCount: Int64(mem), countStyle: .memory))
                }
                LabeledContent("Thermal State") {
                    Text(thermalStateText)
                        .foregroundStyle(thermalColor)
                }
            }

            Section {
                Button {
                    runBenchmark()
                } label: {
                    HStack {
                        Image(systemName: isTesting ? "hourglass" : "play.circle.fill")
                        Text(isTesting ? "Running..." : "Run Benchmark")
                    }
                }
                .disabled(isTesting)
            }
        }
        .navigationTitle("App Launch Time")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func runBenchmark() {
        isTesting = true
        DispatchQueue.global(qos: .userInteractive).async {
            var newResults: [Double] = []
            for _ in 0..<10 {
                let start = CFAbsoluteTimeGetCurrent()
                _ = (0..<10000).reduce(0, +)
                let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
                newResults.append(elapsed)
            }
            DispatchQueue.main.async {
                results.append(contentsOf: newResults)
                iterations += 10
                isTesting = false
            }
        }
    }

    private var thermalStateText: String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    private var thermalColor: Color {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        @unknown default: return .secondary
        }
    }
}
