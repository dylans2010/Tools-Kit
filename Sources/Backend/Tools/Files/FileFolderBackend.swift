import Foundation

@MainActor
final class FileFolderBackend: ObservableObject {
    @Published var items: [ManagedFileItem] = []

    let folderURL: URL
    private let metadataService = ManagedFileMetadataService()
    private let fileNameValidator = FileNameValidator()

    init(folderURL: URL) {
        self.folderURL = folderURL
        reload()
    }

    var totalCount: Int { items.count }
    var totalFiles: Int { items.filter { !$0.isDirectory }.count }
    var totalFolders: Int { items.filter(\.isDirectory).count }
    var totalBytes: Int64 { items.reduce(0) { $0 + $1.size } }

    func reload() {
        items = metadataService.listItems(in: folderURL)
    }

    func createFolder(name: String) {
        let safeName = fileNameValidator.sanitize(name)
        guard !safeName.isEmpty else { return }
        let url = uniqueURL(for: safeName)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        reload()
    }

    func createFile(name: String, type: ManagedFileType, content: String = "") {
        let safeName = fileNameValidator.sanitize(name)
        guard !safeName.isEmpty else { return }
        let url = uniqueURL(for: safeName, fileExtension: type.rawValue)
        try? content.data(using: .utf8)?.write(to: url)
        reload()
    }

    func delete(_ item: ManagedFileItem) {
        try? FileManager.default.removeItem(at: item.url)
        reload()
    }

    func importFiles(urls: [URL]) {
        for url in urls {
            let target = uniqueURL(for: url.lastPathComponent)
            try? FileManager.default.copyItem(at: url, to: target)
        }
        reload()
    }

    private func uniqueURL(for fileName: String, fileExtension: String? = nil) -> URL {
        var baseName = fileName
        var ext = fileExtension
        if ext == nil {
            let u = URL(fileURLWithPath: fileName)
            if !u.pathExtension.isEmpty {
                ext = u.pathExtension
                baseName = u.deletingPathExtension().lastPathComponent
            }
        }
        var candidate = folderURL.appendingPathComponent(baseName)
        if let ext, !ext.isEmpty { candidate = candidate.appendingPathExtension(ext) }
        var index = 1
        while FileManager.default.fileExists(atPath: candidate.path) {
            var fallback = folderURL.appendingPathComponent("\(baseName)-\(index)")
            if let ext, !ext.isEmpty { fallback = fallback.appendingPathExtension(ext) }
            candidate = fallback
            index += 1
        }
        return candidate
    }
}
