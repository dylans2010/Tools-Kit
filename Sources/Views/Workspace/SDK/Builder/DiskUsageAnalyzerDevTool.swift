import SwiftUI

struct DiskUsageAnalyzerDevTool: DevTool {
    let id = "disk-usage-analyzer"
    let name = "Disk Usage Analyzer"
    let category = DevToolCategory.storage
    let icon = "chart.pie.fill"
    let description = "Analyze disk space consumption"

    func render() -> some View {
        DiskUsageAnalyzerView()
    }
}

struct DiskUsageAnalyzerView: View {
    @StateObject private var viewModel = DiskUsageAnalyzerViewModel()

    var body: some View {
        List {
            Section("Storage Distribution") {
                VStack(spacing: 20) {
                    HStack(spacing: 2) {
                        ForEach(viewModel.items) { item in
                            Rectangle()
                                .fill(item.color)
                                .frame(maxWidth: .infinity)
                                .frame(height: 24)
                        }
                    }
                    .clipShape(Capsule())
                    .background(Color.gray.opacity(0.1), in: Capsule())

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(viewModel.items) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Circle().fill(item.color).frame(width: 8, height: 8)
                                    Text(item.name).font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary)
                                }
                                Text(item.size).font(.headline.monospacedDigit())
                                Text("\(Int(item.percentage))% of total").font(.system(size: 8)).foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
                .padding(.vertical, 12)
            }

            Section("Directory Breakdown (Simulated)") {
                DirectoryRow(name: "Documents", size: "1.2 GB", icon: "doc.fill", color: .blue)
                DirectoryRow(name: "Library", size: "840 MB", icon: "books.vertical.fill", color: .orange)
                DirectoryRow(name: "Caches", size: "412 MB", icon: "archivebox.fill", color: .purple)
                DirectoryRow(name: "Temp", size: "48 MB", icon: "trash.fill", color: .secondary)
            }

            Section {
                Button {
                    viewModel.load()
                } label: {
                    Label("Recalculate Usage", systemImage: "arrow.clockwise")
                }

                Button(role: .destructive) {
                    // Simulation
                } label: {
                    Label("Purge System Caches", systemImage: "flame.fill")
                }
            }
        }
        .navigationTitle("Disk Analyzer")
        .onAppear { viewModel.load() }
    }
}

struct DirectoryRow: View {
    let name: String
    let size: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(name).font(.subheadline)
            Spacer()
            Text(size).font(.caption.monospaced()).foregroundStyle(.secondary)
        }
    }
}

struct UsageItem: Identifiable {
    let id = UUID()
    let name: String
    let size: String
    let percentage: Double
    let color: Color
}

class DiskUsageAnalyzerViewModel: ObservableObject {
    @Published var items: [UsageItem] = []

    func load() {
        // Real disk usage info
        let fileManager = FileManager.default
        if let attributes = try? fileManager.attributesOfFileSystem(forPath: NSHomeDirectory()) {
            let total = attributes[.systemSize] as? Int64 ?? 1
            let free = attributes[.systemFreeSize] as? Int64 ?? 0
            let used = total - free

            items = [
                UsageItem(name: "Used Space", size: ByteCountFormatter.string(fromByteCount: used, countStyle: .file), percentage: Double(used)/Double(total)*100, color: .accentColor),
                UsageItem(name: "Free Space", size: ByteCountFormatter.string(fromByteCount: free, countStyle: .file), percentage: Double(free)/Double(total)*100, color: .green)
            ]
        }
    }
}

#Preview {
    DiskUsageAnalyzerView()
}
