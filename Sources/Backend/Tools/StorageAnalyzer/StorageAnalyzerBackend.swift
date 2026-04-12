import Foundation

final class StorageAnalyzerBackend: ObservableObject {
    @Published var totalCapacity: Int64 = 0
    @Published var freeSpace: Int64 = 0
    @Published var usedSpace: Int64 = 0

    func refresh() {
        if let attr = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let total = attr[.systemSize] as? Int64,
           let free = attr[.systemFreeSize] as? Int64 {
            totalCapacity = total
            freeSpace = free
            usedSpace = total - free
        }
    }

    func format(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
