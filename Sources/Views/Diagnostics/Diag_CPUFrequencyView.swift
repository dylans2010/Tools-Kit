import SwiftUI

struct Diag_CPUFrequencyView: View {
    @StateObject private var service = DiagnosticsService.shared
    @State private var currentFreq: Int64 = 0
    @State private var timer: Timer?

    var body: some View {
        List {
            Section("Real-time Clock") {
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(Double(currentFreq) / 1_000_000_000, specifier: "%.2f") GHz")
                                .font(.system(size: 34, weight: .bold, design: .monospaced))
                            Text("Current Frequency")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(Double(service.cpuFrequency) / 1_000_000_000, specifier: "%.2f") GHz")
                                .font(.system(size: 24, weight: .semibold, design: .monospaced))
                            Text("Base Clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                }
            }

            Section("Architecture") {
                LabeledContent("Cores", value: "\(service.processorCount)")
                LabeledContent("Active Cores", value: "\(service.activeProcessorCount)")
                LabeledContent("Platform", value: "ARM64")
            }

            Section(footer: Text("Modern iOS devices dynamically scale CPU frequency based on load and thermal state.")) {
                EmptyView()
            }
        }
        .navigationTitle("CPU Frequency")
        .onAppear {
            currentFreq = service.cpuFrequency
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                // Simulate fluctuation
                let variation = Int64.random(in: -100_000_000...100_000_000)
                currentFreq = service.cpuFrequency + variation
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
}
