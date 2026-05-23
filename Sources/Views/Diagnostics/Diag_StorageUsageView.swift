import SwiftUI

struct Diag_StorageUsageView: View {
    @State private var storageInfo: [(String, String)] = []
    @State private var usagePercent: Double = 0
    @State private var categoryBreakdown: [(String, String, Color, Double)] = []

    var body: some View {
        Form {
            Section("Storage Usage") {
                VStack(spacing: 12) {
                    ZStack {
                        Circle().stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 14)
                        Circle().trim(from: 0, to: usagePercent / 100)
                            .stroke(usageColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack {
                            Text(String(format: "%.0f%%", usagePercent))
                                .font(.title2.bold().monospacedDigit())
                            Text("Used")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 130, height: 130)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Storage Details") {
                ForEach(storageInfo, id: \.0) { info in
                    LabeledContent(info.0) { Text(info.1).font(.caption.monospacedDigit()) }
                }
            }

            if !categoryBreakdown.isEmpty {
                Section("Directory Sizes") {
                    ForEach(categoryBreakdown, id: \.0) { cat in
                        HStack {
                            Circle().fill(cat.2).frame(width: 10, height: 10)
                            Text(cat.0).font(.subheadline)
                            Spacer()
                            Text(cat.1).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Tips") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Settings → General → iPhone Storage for detailed breakdown", systemImage: "gearshape.fill").font(.caption)
                    Label("Offload unused apps to free space", systemImage: "square.and.arrow.down").font(.caption)
                    Label("Clear Safari cache and message attachments", systemImage: "trash").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section { Button { loadStorage() } label: { HStack { Image(systemName: "arrow.clockwise"); Text("Refresh") } } }
        }
        .navigationTitle("Storage Usage")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadStorage() }
    }

    private var usageColor: Color {
        if usagePercent >= 90 { return .red }
        if usagePercent >= 70 { return .orange }
        return .green
    }

    private func loadStorage() {
        var info: [(String, String)] = []
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file

        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let total = attrs[.systemSize] as? Int64,
           let free = attrs[.systemFreeSize] as? Int64 {
            let used = total - free
            usagePercent = Double(used) / Double(total) * 100

            info.append(("Total Storage", formatter.string(fromByteCount: total)))
            info.append(("Used", formatter.string(fromByteCount: used)))
            info.append(("Available", formatter.string(fromByteCount: free)))
            info.append(("Usage", String(format: "%.1f%%", usagePercent)))
        }

        let fm = FileManager.default
        var categories: [(String, String, Color, Double)] = []
        let dirs: [(String, String, Color)] = [
            (NSHomeDirectory() + "/Documents", "Documents", .blue),
            (NSHomeDirectory() + "/Library", "Library", .purple),
            (NSHomeDirectory() + "/tmp", "Temporary", .orange),
            (NSTemporaryDirectory(), "System Temp", .red)
        ]

        for (path, name, color) in dirs {
            let size = directorySize(path: path)
            categories.append((name, formatter.string(fromByteCount: Int64(size)), color, Double(size)))
        }

        storageInfo = info
        categoryBreakdown = categories
    }

    private func directorySize(path: String) -> UInt64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(atPath: path) else { return 0 }
        var total: UInt64 = 0
        while let file = enumerator.nextObject() as? String {
            let fullPath = (path as NSString).appendingPathComponent(file)
            if let attrs = try? fm.attributesOfItem(atPath: fullPath),
               let size = attrs[.size] as? UInt64 {
                total += size
            }
        }
        return total
    }
}
