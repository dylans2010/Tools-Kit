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
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Disk Usage Analyzer",
                description: "Visualize storage distribution across system directories and identify large files.",
                icon: "chart.pie.fill"
            )
            .padding()

            VStack {
                HStack(spacing: 4) {
                    ForEach(viewModel.items) { item in
                        Rectangle()
                            .fill(item.color)
                            .frame(width: CGFloat(item.percentage) * 3, height: 20)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
                .padding()

                List(viewModel.items) { item in
                    HStack {
                        Circle().fill(item.color).frame(width: 10, height: 10)
                        Text(item.name)
                        Spacer()
                        Text(item.size).font(.caption.monospaced())
                        Text("(\(Int(item.percentage))%)").font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onAppear { viewModel.load() }
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
