import SwiftUI

struct Diag_DiskIOBenchmarkView: View {
    @State private var writeSpeed: Double = 0
    @State private var readSpeed: Double = 0
    @State private var isTesting = false
    @State private var testSize: Int = 10 // MB
    @State private var results: [BenchmarkResult] = []
    @State private var progress: Double = 0

    struct BenchmarkResult: Identifiable {
        let id = UUID()
        let timestamp: Date
        let testSizeMB: Int
        let writeSpeedMBs: Double
        let readSpeedMBs: Double
    }

    var body: some View {
        Form {
            Section("Performance") {
                HStack(spacing: 20) {
                    VStack {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        Text(String(format: "%.1f", writeSpeed))
                            .font(.title2.monospacedDigit().bold())
                        Text("MB/s Write")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    VStack {
                        Image(systemName: "arrow.up.doc.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                        Text(String(format: "%.1f", readSpeed))
                            .font(.title2.monospacedDigit().bold())
                        Text("MB/s Read")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 8)
            }

            Section("Test Configuration") {
                Picker("Test Size", selection: $testSize) {
                    Text("1 MB").tag(1)
                    Text("10 MB").tag(10)
                    Text("50 MB").tag(50)
                    Text("100 MB").tag(100)
                }
                .pickerStyle(.segmented)

                if isTesting {
                    ProgressView(value: progress)
                    Text("Testing...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button {
                    runBenchmark()
                } label: {
                    HStack {
                        Image(systemName: "gauge.with.dots.needle.67percent")
                        Text(isTesting ? "Testing..." : "Run Benchmark")
                    }
                }
                .disabled(isTesting)
            }

            Section("Storage Info") {
                let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
                if let total = attrs?[.systemSize] as? Int64,
                   let free = attrs?[.systemFreeSize] as? Int64 {
                    LabeledContent("Total") { Text(formatBytes(total)) }
                    LabeledContent("Free") { Text(formatBytes(free)).foregroundStyle(.green) }
                    LabeledContent("Used") { Text(formatBytes(total - free)).foregroundStyle(.orange) }
                }
                LabeledContent("File System") {
                    let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
                    Text((attrs?[.systemFileNumber] != nil) ? "APFS" : "Unknown")
                }
            }

            if !results.isEmpty {
                Section("History") {
                    ForEach(results, id: \.id) { result in
                        HStack {
                            Text(result.timestamp, style: .time)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Text("\(result.testSizeMB)MB")
                                .font(.caption)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(format: "W: %.1f MB/s", result.writeSpeedMBs))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.blue)
                                Text(String(format: "R: %.1f MB/s", result.readSpeedMBs))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Disk I/O Benchmark")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func runBenchmark() {
        isTesting = true
        progress = 0
        writeSpeed = 0
        readSpeed = 0

        DispatchQueue.global(qos: .userInitiated).async {
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("disk_benchmark_\(UUID().uuidString)")
            let dataSize = testSize * 1024 * 1024
            let data = Data(repeating: 0xAB, count: dataSize)

            // Write test
            DispatchQueue.main.async { progress = 0.1 }
            let writeStart = CFAbsoluteTimeGetCurrent()
            do {
                try data.write(to: fileURL, options: .atomic)
            } catch {
                DispatchQueue.main.async { isTesting = false }
                return
            }
            let writeElapsed = CFAbsoluteTimeGetCurrent() - writeStart
            let wSpeed = Double(testSize) / writeElapsed

            DispatchQueue.main.async { progress = 0.5; writeSpeed = wSpeed }

            // Read test
            let readStart = CFAbsoluteTimeGetCurrent()
            _ = try? Data(contentsOf: fileURL)
            let readElapsed = CFAbsoluteTimeGetCurrent() - readStart
            let rSpeed = Double(testSize) / readElapsed

            // Cleanup
            try? FileManager.default.removeItem(at: fileURL)

            DispatchQueue.main.async {
                readSpeed = rSpeed
                progress = 1.0
                isTesting = false
                results.insert(BenchmarkResult(timestamp: Date(), testSizeMB: testSize, writeSpeedMBs: wSpeed, readSpeedMBs: rSpeed), at: 0)
                if results.count > 10 { results.removeLast() }
            }
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
