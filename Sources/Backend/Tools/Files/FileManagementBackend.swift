import Foundation

struct ManagedFileItem: Identifiable, Hashable {
    var id: String { url.path }
    let url: URL
    let isDirectory: Bool
    let size: Int64
    let modifiedAt: Date
}

enum ManagedFileType: String, CaseIterable, Identifiable {
    case text = "txt"
    case plist = "plist"
    case json = "json"
    case xml = "xml"

    var id: String { rawValue }
}

enum FileTemplate: String, CaseIterable, Identifiable {
    case html = "HTML"
    case swift = "Swift"
    case python = "Python"
    case yaml = "YAML"
    case readme = "README"

    var id: String { rawValue }

    var fileName: String {
        switch self {
        case .html: return "index.html"
        case .swift: return "main.swift"
        case .python: return "main.py"
        case .yaml: return "config.yaml"
        case .readme: return "README.md"
        }
    }

    var contents: String {
        switch self {
        case .html: return "<!doctype html>\n<html><head><title>New File</title></head><body>\n<h1>Hello</h1>\n</body></html>\n"
        case .swift: return "import Foundation\n\nprint(\"Hello, world\")\n"
        case .python: return "def main():\n    print(\"Hello, world\")\n\nif __name__ == '__main__':\n    main()\n"
        case .yaml: return "name: example\nversion: 1\n"
        case .readme: return "# New Project\n\nDescribe your project here.\n"
        }
    }
}

@MainActor
final class FileManagementBackend: ObservableObject {
    @Published var items: [ManagedFileItem] = []
    @Published var selectedItem: ManagedFileItem?
    @Published var aiSummary: String = ""
    @Published var isSummarizing = false

    let rootURL: URL

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        rootURL = documents.appendingPathComponent("FilesWorkspace", isDirectory: true)
        if !FileManager.default.fileExists(atPath: rootURL.path) {
            try? FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        }
        reload()
    }

    var totalCount: Int { items.count }
    var totalFolders: Int { items.filter(\.isDirectory).count }
    var totalFiles: Int { items.filter { !$0.isDirectory }.count }
    var totalBytes: Int64 { items.reduce(0) { $0 + $1.size } }

    func reload() {
        let urls = (try? FileManager.default.contentsOfDirectory(at: rootURL, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey], options: [.skipsHiddenFiles])) ?? []
        items = urls.compactMap { url in
            guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey]) else { return nil }
            return ManagedFileItem(
                url: url,
                isDirectory: values.isDirectory ?? false,
                size: Int64(values.fileSize ?? 0),
                modifiedAt: values.contentModificationDate ?? Date()
            )
        }
        .sorted { $0.url.lastPathComponent.localizedCaseInsensitiveCompare($1.url.lastPathComponent) == .orderedAscending }
    }

    func createFolder(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let folderURL = rootURL.appendingPathComponent(trimmed, isDirectory: true)
        try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        reload()
    }

    func createFile(name: String, type: ManagedFileType, content: String = "") {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let fileURL = rootURL.appendingPathComponent(trimmed).appendingPathExtension(type.rawValue)
        try? content.data(using: .utf8)?.write(to: fileURL)
        reload()
    }

    func createFromTemplate(_ template: FileTemplate) {
        let fileURL = rootURL.appendingPathComponent(template.fileName)
        try? template.contents.data(using: .utf8)?.write(to: fileURL)
        reload()
    }

    func importFiles(urls: [URL]) {
        for url in urls {
            let target = rootURL.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.removeItem(at: target)
            try? FileManager.default.copyItem(at: url, to: target)
        }
        reload()
    }

    func delete(_ item: ManagedFileItem) {
        try? FileManager.default.removeItem(at: item.url)
        if selectedItem?.id == item.id { selectedItem = nil }
        reload()
    }

    func summarizeSelectedFile() async {
        guard let selectedItem, !selectedItem.isDirectory,
              let data = try? Data(contentsOf: selectedItem.url),
              let text = String(data: data, encoding: .utf8) else {
            aiSummary = "Select a text-based file to summarize."
            return
        }

        isSummarizing = true
        defer { isSummarizing = false }

        do {
            aiSummary = try await AIService.shared.summarize(text: text)
        } catch {
            aiSummary = "Failed to summarize: \(error.localizedDescription)"
        }
    }
}
