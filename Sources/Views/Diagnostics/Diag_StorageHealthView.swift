import SwiftUI

struct Diag_StorageHealthView: View {
    @State private var totalSpace: Int64 = 0
    @State private var freeSpace: Int64 = 0
    @State private var usedSpace: Int64 = 0
    @State private var importantSpace: Int64 = 0
    @State private var opportunisticSpace: Int64 = 0
    @State private var writeSpeed: Double = 0
    @State private var readSpeed: Double = 0
    @State private var isTesting = false

    var body: some View {
        Form {
            Section("Storage Overview") {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color(.tertiarySystemFill), lineWidth: 14)
                        Circle()
                            .trim(from: 0, to: usagePercent)
                            .stroke(usageColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack {
                            Text("\(Int(usagePercent * 100))%")
                                .font(.title2.bold().monospacedDigit())
                            Text("Used")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 120, height: 120)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Capacity") {
                LabeledContent("Total") { Text(formattedBytes(totalSpace)).monospacedDigit() }
                LabeledContent("Used") { Text(formattedBytes(usedSpace)).monospacedDigit() }
                LabeledContent("Available") { Text(formattedBytes(freeSpace)).monospacedDigit() }
                if importantSpace > 0 {
                    LabeledContent("Important") { Text(formattedBytes(importantSpace)).monospacedDigit() }
                }
                if opportunisticSpace > 0 {
                    LabeledContent("Purgeable") { Text(formattedBytes(opportunisticSpace)).monospacedDigit() }
                }
            }

            Section("I/O Speed") {
                LabeledContent("Write Speed") {
                    Text(writeSpeed > 0 ? String(format: "%.1f MB/s", writeSpeed) : "Not tested")
                        .monospacedDigit()
                }
                LabeledContent("Read Speed") {
                    Text(readSpeed > 0 ? String(format: "%.1f MB/s", readSpeed) : "Not tested")
                        .monospacedDigit()
                }
            }

            Section {
                Button {
                    runIOTest()
                } label: {
                    HStack {
                        Image(systemName: isTesting ? "hourglass" : "bolt.fill")
                        Text(isTesting ? "Testing..." : "Run I/O Speed Test")
                    }
                }
                .disabled(isTesting)
            }
        }
        .navigationTitle("Storage Health")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadStorageInfo() }
    }

    private var usagePercent: CGFloat {
        guard totalSpace > 0 else { return 0 }
        return CGFloat(usedSpace) / CGFloat(totalSpace)
    }

    private var usageColor: Color {
        if usagePercent > 0.9 { return .red }
        if usagePercent > 0.75 { return .orange }
        return .green
    }

    private func loadStorageInfo() {
        let fm = FileManager.default
        if let attrs = try? fm.attributesOfFileSystem(forPath: NSHomeDirectory()) {
            totalSpace = attrs[.systemSize] as? Int64 ?? 0
            freeSpace = attrs[.systemFreeSize] as? Int64 ?? 0
            usedSpace = totalSpace - freeSpace
        }
        if let url = fm.urls(for: .documentDirectory, in: .userDomainMask).first,
           let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeAvailableCapacityForOpportunisticUsageKey]) {
            importantSpace = values.volumeAvailableCapacityForImportantUsage ?? 0
            opportunisticSpace = values.volumeAvailableCapacityForOpportunisticUsage ?? 0
        }
    }

    private func runIOTest() {
        isTesting = true
        DispatchQueue.global(qos: .userInitiated).async {
            let testData = Data(repeating: 0xAA, count: 10_000_000)
            let tempFile = NSTemporaryDirectory() + "io_test_\(UUID().uuidString)"

            let writeStart = CFAbsoluteTimeGetCurrent()
            try? testData.write(to: URL(fileURLWithPath: tempFile))
            let writeTime = CFAbsoluteTimeGetCurrent() - writeStart
            let wSpeed = Double(testData.count) / writeTime / 1_000_000

            let readStart = CFAbsoluteTimeGetCurrent()
            _ = try? Data(contentsOf: URL(fileURLWithPath: tempFile))
            let readTime = CFAbsoluteTimeGetCurrent() - readStart
            let rSpeed = Double(testData.count) / readTime / 1_000_000

            try? FileManager.default.removeItem(atPath: tempFile)

            DispatchQueue.main.async {
                writeSpeed = wSpeed
                readSpeed = rSpeed
                isTesting = false
            }
        }
    }

    private func formattedBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
