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

    var body: some View {
        VStack(spacing: 0) {
            DevToolHeader(
                title: "Cache Viewer",
                description: "Monitor cached data size and clear various cache buckets to free up space.",
                icon: "archivebox"
            )
            .padding()

            List {
                Section("Cache Summary") {
                    LabeledContent("Total Cache Size", value: viewModel.totalCacheSize)
                    Button("Clear All Cache", role: .destructive) { viewModel.clearAll() }
                }

                Section("Cache Buckets") {
                    ForEach(viewModel.buckets) { bucket in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(bucket.name).font(.subheadline.bold())
                                Text(bucket.path).font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(bucket.size).font(.caption.monospaced())
                        }
                    }
                }
            }
        }
        .onAppear { viewModel.load() }
    }
}

struct CacheBucket: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let size: String
}

class CacheViewerViewModel: ObservableObject {
    @Published var totalCacheSize = "0 MB"
    @Published var buckets: [CacheBucket] = []

    func load() {
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        totalCacheSize = calculateSize(at: cacheURL)

        // Mock sub-buckets
        buckets = [
            CacheBucket(name: "Image Cache", path: "/Caches/Images", size: "1.2 MB"),
            CacheBucket(name: "Network Response Cache", path: "/Caches/Network", size: "4.5 MB"),
            CacheBucket(name: "Temporary Files", path: "/tmp", size: "800 KB")
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
