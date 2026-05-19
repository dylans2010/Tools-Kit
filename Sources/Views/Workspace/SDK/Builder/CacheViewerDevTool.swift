import SwiftUI

struct CacheViewerDevTool: DevTool {
    let id = "cache-viewer"
    let name = "Cache Viewer"
    let category = DevToolCategory.storage
    let icon = "archivebox"
    let description = "Inspect and clear application cache"

    func render() -> some View {
        CacheViewerView()
    }
}

struct CacheViewerView: View {
    @StateObject private var viewModel = CacheViewerViewModel()
    @State private var showingPruneAlert = false

    var body: some View {
        List {
            Section("Global Storage") {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(viewModel.totalCacheSize).font(.system(size: 32, weight: .black, design: .rounded))
                            Text("Total Indexed Cache").font(.caption2.bold()).foregroundStyle(.secondary)
                        }
                        Spacer()
                        CircularUsageView(percentage: viewModel.usagePercentage)
                            .frame(width: 50, height: 50)
                    }

                    HStack(spacing: 12) {
                        Button(role: .destructive) { showingPruneAlert = true } label: {
                            Label("Purge Everything", systemImage: "trash.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        Button { viewModel.load() } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Storage Buckets (\(viewModel.buckets.count))") {
                ForEach(viewModel.buckets) { bucket in
                    BucketRow(bucket: bucket)
                }
            }

            Section("Management Tools") {
                Toggle("Auto-prune large items", isOn: .constant(true))
                Toggle("Log cache evictions", isOn: .constant(false))

                Button("Run Orphan Analysis") { /* Simulation */ }
                Button("Simulate Low Disk Warning") { /* Simulation */ }
            }
        }
        .navigationTitle("Cache Lab")
        .alert("Purge Cache?", isPresented: $showingPruneAlert) {
            Button("Delete All", role: .destructive) { viewModel.clearAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all temporary files, network caches, and processed images.")
        }
        .onAppear { viewModel.load() }
    }
}

struct CircularUsageView: View {
    let percentage: Double
    var body: some View {
        ZStack {
            Circle().stroke(Color.gray.opacity(0.1), lineWidth: 6)
            Circle()
                .trim(from: 0, to: percentage / 100)
                .stroke(percentage > 80 ? Color.red : Color.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(percentage))%").font(.system(size: 10, weight: .bold))
        }
    }
}

struct BucketRow: View {
    let bucket: CacheBucket
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: bucket.icon)
                .foregroundStyle(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(bucket.name).font(.subheadline.bold())
                Text(bucket.path).font(.system(size: 9)).foregroundStyle(.secondary).lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(bucket.size).font(.system(size: 11, design: .monospaced))
                Text("\(bucket.itemCount) items").font(.system(size: 8)).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct CacheBucket: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let size: String
    let icon: String
    let itemCount: Int
}

class CacheViewerViewModel: ObservableObject {
    @Published var totalCacheSize = "0.0 MB"
    @Published var usagePercentage = 12.0
    @Published var buckets: [CacheBucket] = []

    func load() {
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        totalCacheSize = calculateSize(at: cacheURL)
        usagePercentage = Double.random(in: 5...45)

        // Mock sub-buckets
        buckets = [
            CacheBucket(name: "Image Assets", path: "/Caches/Images", size: "14.2 MB", icon: "photo.on.rectangle", itemCount: 142),
            CacheBucket(name: "API Responses", path: "/Caches/Network", size: "4.5 MB", icon: "network", itemCount: 890),
            CacheBucket(name: "WebView Data", path: "/Caches/WebKit", size: "128 MB", icon: "globe", itemCount: 12),
            CacheBucket(name: "Crash Logs", path: "/Caches/Logs", size: "240 KB", icon: "doc.text.fill", itemCount: 3),
            CacheBucket(name: "Temp Uploads", path: "/tmp", size: "800 KB", icon: "arrow.up.doc", itemCount: 1)
        ]
    }

    func clearAll() {
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        try? FileManager.default.removeItem(at: cacheURL)
        load()
    }

    private func calculateSize(at url: URL) -> String {
        let resources = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [])
        let total: Int = resources?.reduce(0) { partialResult, fileURL in
            let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return partialResult + fileSize
        } ?? 0
        return ByteCountFormatter.string(fromByteCount: Int64(total), countStyle: .file)
    }
}

#Preview {
    CacheViewerView()
}
