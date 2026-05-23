import SwiftUI

struct Diag_CPUBenchmarkView: View {
    @State private var isRunning = false
    @State private var singleScore: Int = 0
    @State private var multiScore: Int = 0
    @State private var results: [(String, String)] = []
    @State private var hasRun = false

    var body: some View {
        Form {
            Section("CPU Benchmark") {
                VStack(spacing: 12) {
                    Image(systemName: "cpu")
                        .font(.system(size: 52))
                        .foregroundStyle(.blue)
                    if hasRun {
                        HStack(spacing: 30) {
                            VStack {
                                Text("\(singleScore)")
                                    .font(.title.bold().monospacedDigit())
                                    .foregroundStyle(.blue)
                                Text("Single Core")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            VStack {
                                Text("\(multiScore)")
                                    .font(.title.bold().monospacedDigit())
                                    .foregroundStyle(.green)
                                Text("Multi Core")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    Text("Measures integer, floating-point, and memory throughput")
                        .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            if !results.isEmpty {
                Section("Details") {
                    ForEach(results, id: \.0) { r in
                        LabeledContent(r.0) { Text(r.1).font(.caption.monospacedDigit()) }
                    }
                }
            }

            Section {
                Button {
                    runBenchmark()
                } label: {
                    HStack {
                        if isRunning { ProgressView().scaleEffect(0.8) }
                        else { Image(systemName: "play.circle.fill") }
                        Text(isRunning ? "Running..." : hasRun ? "Run Again" : "Start Benchmark")
                    }
                }
                .disabled(isRunning)
            }

            Section("System Info") {
                LabeledContent("CPU Cores") { Text("\(ProcessInfo.processInfo.processorCount)") }
                LabeledContent("Active Cores") { Text("\(ProcessInfo.processInfo.activeProcessorCount)") }
                LabeledContent("RAM") { Text(ByteCountFormatter.string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory), countStyle: .memory)) }
            }
        }
        .navigationTitle("CPU Benchmark")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func runBenchmark() {
        isRunning = true
        results = []

        DispatchQueue.global(qos: .userInitiated).async {
            let intResult = benchmarkInteger()
            let fpResult = benchmarkFloat()
            let memResult = benchmarkMemory()
            let singleTotal = intResult.single + fpResult.single + memResult.single
            let multiTotal = intResult.multi + fpResult.multi + memResult.multi

            DispatchQueue.main.async {
                singleScore = singleTotal
                multiScore = multiTotal
                results = [
                    ("Integer (Single)", "\(intResult.single)"),
                    ("Integer (Multi)", "\(intResult.multi)"),
                    ("Float (Single)", "\(fpResult.single)"),
                    ("Float (Multi)", "\(fpResult.multi)"),
                    ("Memory (Single)", "\(memResult.single)"),
                    ("Memory (Multi)", "\(memResult.multi)"),
                    ("Total Single", "\(singleTotal)"),
                    ("Total Multi", "\(multiTotal)"),
                    ("Thermal", thermalStr())
                ]
                isRunning = false
                hasRun = true
            }
        }
    }

    private func benchmarkInteger() -> (single: Int, multi: Int) {
        let iterations = 5_000_000
        let singleStart = CFAbsoluteTimeGetCurrent()
        var sum: Int64 = 0
        for i in 0..<iterations {
            sum += Int64(i * 7 + 3)
            sum ^= Int64(i >> 2)
        }
        let singleTime = CFAbsoluteTimeGetCurrent() - singleStart
        _ = sum

        let multiStart = CFAbsoluteTimeGetCurrent()
        let cores = ProcessInfo.processInfo.activeProcessorCount
        let group = DispatchGroup()
        for _ in 0..<cores {
            group.enter()
            DispatchQueue.global().async {
                var s: Int64 = 0
                for i in 0..<iterations {
                    s += Int64(i * 7 + 3)
                    s ^= Int64(i >> 2)
                }
                _ = s
                group.leave()
            }
        }
        group.wait()
        let multiTime = CFAbsoluteTimeGetCurrent() - multiStart

        return (single: max(1, Int(1000 / max(singleTime, 0.001))), multi: max(1, Int(1000 / max(multiTime, 0.001)) * cores))
    }

    private func benchmarkFloat() -> (single: Int, multi: Int) {
        let iterations = 2_000_000
        let singleStart = CFAbsoluteTimeGetCurrent()
        var result: Double = 1.0
        for i in 1...iterations {
            result += sin(Double(i)) * cos(Double(i))
        }
        let singleTime = CFAbsoluteTimeGetCurrent() - singleStart
        _ = result

        let multiStart = CFAbsoluteTimeGetCurrent()
        let cores = ProcessInfo.processInfo.activeProcessorCount
        let group = DispatchGroup()
        for _ in 0..<cores {
            group.enter()
            DispatchQueue.global().async {
                var r: Double = 1.0
                for i in 1...iterations {
                    r += sin(Double(i)) * cos(Double(i))
                }
                _ = r
                group.leave()
            }
        }
        group.wait()
        let multiTime = CFAbsoluteTimeGetCurrent() - multiStart

        return (single: max(1, Int(1000 / max(singleTime, 0.001))), multi: max(1, Int(1000 / max(multiTime, 0.001)) * cores))
    }

    private func benchmarkMemory() -> (single: Int, multi: Int) {
        let size = 1_000_000
        let singleStart = CFAbsoluteTimeGetCurrent()
        var array = [Int](repeating: 0, count: size)
        for i in 0..<size { array[i] = i * 3 }
        var total = 0
        for i in 0..<size { total += array[i] }
        let singleTime = CFAbsoluteTimeGetCurrent() - singleStart
        _ = total

        let multiStart = CFAbsoluteTimeGetCurrent()
        let cores = ProcessInfo.processInfo.activeProcessorCount
        let group = DispatchGroup()
        for _ in 0..<cores {
            group.enter()
            DispatchQueue.global().async {
                var arr = [Int](repeating: 0, count: size)
                for i in 0..<size { arr[i] = i * 3 }
                var t = 0
                for i in 0..<size { t += arr[i] }
                _ = t
                group.leave()
            }
        }
        group.wait()
        let multiTime = CFAbsoluteTimeGetCurrent() - multiStart

        return (single: max(1, Int(500 / max(singleTime, 0.001))), multi: max(1, Int(500 / max(multiTime, 0.001)) * cores))
    }

    private func thermalStr() -> String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return "Nominal"; case .fair: return "Fair"; case .serious: return "Serious"; case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }
}
