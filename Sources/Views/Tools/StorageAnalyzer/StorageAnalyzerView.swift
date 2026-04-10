import SwiftUI

struct StorageAnalyzerView: View {
    @State private var totalSpace: Int64 = 0
    @State private var freeSpace: Int64 = 0
    @State private var usedSpace: Int64 = 0

    var body: some View {
        List {
            Section("Device Storage") {
                VStack(spacing: 20) {
                    Circle()
                        .trim(from: 0, to: CGFloat(usedSpace) / CGFloat(totalSpace == 0 ? 1 : totalSpace))
                        .stroke(Color.blue, lineWidth: 20)
                        .frame(height: 150)
                        .overlay(
                            VStack {
                                Text("\(Int((Double(usedSpace) / Double(totalSpace == 0 ? 1 : totalSpace)) * 100))%")
                                    .font(.title)
                                    .bold()
                                Text("Used")
                                    .font(.caption)
                            }
                        )
                        .padding()

                    HStack {
                        StorageInfoItem(title: "Free", value: formatBytes(freeSpace), color: .green)
                        Spacer()
                        StorageInfoItem(title: "Used", value: formatBytes(usedSpace), color: .blue)
                        Spacer()
                        StorageInfoItem(title: "Total", value: formatBytes(totalSpace), color: .gray)
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Storage Analyzer")
        .onAppear(perform: calculateStorage)
    }

    private func calculateStorage() {
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()) {
            totalSpace = attrs[.systemSize] as? Int64 ?? 0
            freeSpace = attrs[.systemFreeSize] as? Int64 ?? 0
            usedSpace = totalSpace - freeSpace
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

struct StorageInfoItem: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(value).font(.headline).foregroundColor(color)
        }
    }
}

struct StorageAnalyzerTool: Tool {
    let name = "Storage Tool"
    let icon = "internaldrive"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Detailed breakdown of device storage usage"
    let requiresAPI = false
    var view: AnyView { AnyView(StorageAnalyzerView()) }
}
