import SwiftUI

struct CacheViewerDevTool: DevTool {
    let id = "cache-viewer"
    let name = "Cache Viewer"
    let category = DevToolCategory.storage
    let icon = "archivebox"
    let description = "View application cache size and items"

    func render() -> some View {
        CacheViewerView()
    }
}

struct CacheViewerView: View {
    @State private var cacheSize = "Calculating..."

    var body: some View {
        Form {
            Section("Cache Info") {
                LabeledContent("Total Size", value: cacheSize)
                Button("Clear Cache", role: .destructive) {
                    URLCache.shared.removeAllCachedResponses()
                    calculateSize()
                }
            }
        }
        .onAppear {
            calculateSize()
        }
    }

    private func calculateSize() {
        let size = URLCache.shared.currentDiskUsage
        cacheSize = "\(size / 1024 / 1024) MB"
    }
}
