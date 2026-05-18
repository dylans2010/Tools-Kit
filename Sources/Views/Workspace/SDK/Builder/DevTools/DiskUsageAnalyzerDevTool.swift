import SwiftUI

struct DiskUsageAnalyzerTool: DevTool {
    let id = UUID()
    let name = "Disk Usage Analyzer"
    let category: DevToolCategory = .storage
    let icon = "chart.pie"
    let description = "Analyze disk space usage by directory"
    func render() -> some View { DiskUsageAnalyzerDevToolView() }
}

struct DiskUsageAnalyzerDevToolView: View {
    @State private var entries: [(String, Int64)] = []
    @State private var totalSpace: Int64 = 0
    @State private var freeSpace: Int64 = 0

    var body: some View {
        Form {
            Section("Device Storage") {
                LabeledContent("Total", value: formatBytes(totalSpace))
                LabeledContent("Free", value: formatBytes(freeSpace))
                LabeledContent("Used", value: formatBytes(totalSpace - freeSpace))
                if totalSpace > 0 {
                    ProgressView(value: Double(totalSpace - freeSpace), total: Double(totalSpace))
                        .tint(usageColor)
                }
            }
            Section {
                Button("Analyze App Storage") { analyze() }
            }
            if !entries.isEmpty {
                Section("App Directories") {
                    ForEach(entries, id: \.0) { name, size in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(name).font(.subheadline)
                                Text(formatBytes(size)).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let total = entries.map(\.1).max(), total > 0 {
                                GeometryReader { geo in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.accentColor.opacity(0.3))
                                        .frame(width: geo.size.width * CGFloat(size) / CGFloat(total))
                                }
                                .frame(width: 80, height: 12)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Disk Usage Analyzer")
        .onAppear { loadDiskInfo() }
    }

    private func loadDiskInfo() {
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()) {
            totalSpace = (attrs[.systemSize] as? Int64) ?? 0
            freeSpace = (attrs[.systemFreeSize] as? Int64) ?? 0
        }
    }

    private func analyze() {
        let dirs: [(String, FileManager.SearchPathDirectory)] = [
            ("Documents", .documentDirectory), ("Caches", .cachesDirectory),
            ("Library", .libraryDirectory), ("Application Support", .applicationSupportDirectory),
        ]
        entries = dirs.compactMap { name, dir in
            guard let url = FileManager.default.urls(for: dir, in: .userDomainMask).first else { return nil }
            return (name, directorySize(url))
        }
        entries.append(("Temp", directorySize(FileManager.default.temporaryDirectory)))
        entries.sort { $0.1 > $1.1 }
    }

    private func directorySize(_ url: URL) -> Int64 {
        guard let en = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: Int64 = 0
        for case let f as URL in en { total += Int64((try? f.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) }
        return total
    }

    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private var usageColor: Color {
        let ratio = Double(totalSpace - freeSpace) / Double(max(1, totalSpace))
        return ratio > 0.9 ? .red : ratio > 0.7 ? .orange : .green
    }
}
