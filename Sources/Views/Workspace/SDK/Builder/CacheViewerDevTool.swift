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
        List {
            Section(header: Text("Cache Summary")) {
                LabeledContent("Total Cache Size", value: viewModel.totalCacheSize)
                Button("Clear All Cache", role: .destructive) { viewModel.clearAll() }
            }

            Section(header: Text("Cache Buckets")) {
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

        do {
            let subdirs = try FileManager.default.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
            buckets = subdirs.map { url in
                CacheBucket(
                    name: url.lastPathComponent,
                    path: url.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"),
                    size: calculateSize(at: url)
                )
            }.sorted(by: { $0.name < $1.name })

            // Add tmp directory too
            let tmpURL = FileManager.default.temporaryDirectory
            buckets.append(CacheBucket(
                name: "Temporary Files",
                path: "/tmp",
                size: calculateSize(at: tmpURL)
            ))
        } catch {
            buckets = []
        }
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
