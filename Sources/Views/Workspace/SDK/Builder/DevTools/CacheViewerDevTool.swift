import SwiftUI

struct CacheViewerTool: DevTool {
    let id = UUID()
    let name = "Cache Viewer"
    let category: DevToolCategory = .storage
    let icon = "archivebox"
    let description = "Inspect URLCache and app caches"
    func render() -> some View { CacheViewerDevToolView() }
}

struct CacheViewerDevToolView: View {
    @State private var cacheInfo: [(String, String)] = []

    var body: some View {
        Form {
            Section {
                Button("Refresh") { loadCacheInfo() }
                Button("Clear URL Cache", role: .destructive) {
                    URLCache.shared.removeAllCachedResponses()
                    loadCacheInfo()
                }
            }
            Section("URL Cache") {
                ForEach(cacheInfo, id: \.0) { key, value in
                    LabeledContent(key, value: value)
                }
            }
            Section("Cache Directories") {
                if let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
                    Text(cachesURL.path).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                    let size = directorySize(cachesURL)
                    LabeledContent("Total Size", value: ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                }
            }
        }
        .navigationTitle("Cache Viewer")
        .onAppear { loadCacheInfo() }
    }

    private func loadCacheInfo() {
        let cache = URLCache.shared
        cacheInfo = [
            ("Memory Capacity", ByteCountFormatter.string(fromByteCount: Int64(cache.memoryCapacity), countStyle: .memory)),
            ("Memory Usage", ByteCountFormatter.string(fromByteCount: Int64(cache.currentMemoryUsage), countStyle: .memory)),
            ("Disk Capacity", ByteCountFormatter.string(fromByteCount: Int64(cache.diskCapacity), countStyle: .file)),
            ("Disk Usage", ByteCountFormatter.string(fromByteCount: Int64(cache.currentDiskUsage), countStyle: .file)),
        ]
    }

    private func directorySize(_ url: URL) -> Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        return total
    }
}
