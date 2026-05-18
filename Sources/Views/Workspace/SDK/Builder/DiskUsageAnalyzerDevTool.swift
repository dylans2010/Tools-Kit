import SwiftUI

struct DiskUsageAnalyzerDevTool: DevTool {
    let id = "disk-usage-analyzer"
    let name = "Disk Usage Analyzer"
    let category = DevToolCategory.storage
    let icon = "chart.pie"
    let description = "Analyze disk space distribution"

    func render() -> some View {
        DiskUsageAnalyzerView()
    }
}

struct DiskUsageAnalyzerView: View {
    @State private var freeSpace = "Calculating..."
    @State private var totalSpace = "Calculating..."

    var body: some View {
        Form {
            Section("Device Disk Space") {
                LabeledContent("Free", value: freeSpace)
                LabeledContent("Total", value: totalSpace)
            }

            Section("System Mounts") {
                LabeledContent("Root", value: "/")
                LabeledContent("User", value: "/var/mobile")
            }
        }
        .onAppear {
            update()
        }
    }

    private func update() {
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let free = attrs[.systemFreeSize] as? Int64,
           let total = attrs[.systemSize] as? Int64 {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            freeSpace = formatter.string(fromByteCount: free)
            totalSpace = formatter.string(fromByteCount: total)
        }
    }
}
