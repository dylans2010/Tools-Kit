import SwiftUI

struct Diag_CPUStressTestView: View {
    @State private var isRunning = false
    @State private var progress: Double = 0
    @State private var elapsedTime: TimeInterval = 0
    @State private var computationsPerSecond: Double = 0
    @State private var thermalState: String = "Nominal"
    @State private var timer: Timer?
    @State private var stressTask: Task<Void, Never>?
    @State private var coreUsages: [Double] = []

    var body: some View {
        Form {
            Section("CPU Stress Test") {
                VStack(spacing: 12) {
                    Image(systemName: "cpu")
                        .font(.system(size: 50))
                        .foregroundStyle(isRunning ? .orange : .blue)
                        .symbolEffect(.pulse, isActive: isRunning)

                    if isRunning {
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                            .tint(.orange)

                        Text("\(Int(progress * 100))%")
                            .font(.title.monospacedDigit().bold())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("System Info") {
                LabeledContent("Processor Cores") {
                    Text("\(ProcessInfo.processInfo.activeProcessorCount)")
                }

                if !coreUsages.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Core Load Breakdown")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        ForEach(0..<coreUsages.count, id: \.self) { i in
                            HStack {
                                Text("Core \(i)")
                                    .font(.caption.monospaced())
                                    .frame(width: 50, alignment: .leading)

                                ProgressView(value: coreUsages[i], total: 100)
                                    .tint(coreUsages[i] > 80 ? .red : .blue)

                                Text("\(Int(coreUsages[i]))%")
                                    .font(.caption2.monospacedDigit())
                                    .frame(width: 35, alignment: .trailing)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                LabeledContent("Thermal State") {
                    Text(thermalState)
                        .foregroundStyle(thermalColor)
                }
                if isRunning {
                    LabeledContent("Elapsed") {
                        Text("\(elapsedTime, specifier: "%.1f")s")
                            .monospacedDigit()
                    }
                    LabeledContent("Ops/sec") {
                        Text("\(computationsPerSecond, specifier: "%.0f")")
                            .monospacedDigit()
                    }
                }
            }

            Section {
                Button {
                    if isRunning { stopTest() } else { startTest() }
                } label: {
                    HStack {
                        Image(systemName: isRunning ? "stop.circle.fill" : "play.circle.fill")
                        Text(isRunning ? "Stop Test" : "Start CPU Stress Test")
                    }
                }
            }

            Section {
                Text("This performs intensive but safe floating-point calculations across multiple cores. Monitor thermal state during the test.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("CPU Stress Test")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopTest() }
    }

    private var thermalColor: Color {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        @unknown default: return .gray
        }
    }

    private func updateThermalState() {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: thermalState = "Nominal"
        case .fair: thermalState = "Fair"
        case .serious: thermalState = "Serious"
        case .critical: thermalState = "Critical"
        @unknown default: thermalState = "Unknown"
        }
    }

    private func startTest() {
        isRunning = true
        progress = 0
        elapsedTime = 0
        let startTime = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            elapsedTime = Date().timeIntervalSince(startTime)
            updateThermalState()
            coreUsages = DiagnosticsService.shared.getProcessorUsage()
        }

        let totalIterations = 10_000_000
        stressTask = Task.detached(priority: .userInitiated) {
            var ops: Int = 0
            let cores = ProcessInfo.processInfo.activeProcessorCount
            let perCore = totalIterations / cores

            await withTaskGroup(of: Int.self) { group in
                for _ in 0..<cores {
                    group.addTask {
                        var x: Double = 1.0
                        for i in 0..<perCore {
                            x = sin(x) * cos(x) + sqrt(abs(x) + 1.0)
                            if i % (perCore / 20) == 0 {
                                let p = Double(i) / Double(perCore)
                                await MainActor.run { progress = p }
                            }
                        }
                        return perCore
                    }
                }
                for await count in group {
                    ops += count
                }
            }

            let elapsed = Date().timeIntervalSince(startTime)
            await MainActor.run {
                computationsPerSecond = Double(ops) / elapsed
                progress = 1.0
                stopTest()
            }
        }
    }

    private func stopTest() {
        stressTask?.cancel()
        stressTask = nil
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
}
