import Foundation

// Models are defined in FileModels.swift

@MainActor
final class FileManagementBackend: ObservableObject {
    @Published var items: [ManagedFileItem] = []
    @Published var selectedItem: ManagedFileItem?
    @Published var aiSummary: String = ""
    @Published var isSummarizing = false

    let rootURL: URL
    private let workspaceManager: FileWorkspaceManager
    private let metadataService = ManagedFileMetadataService()
    private let fileNameValidator = FileNameValidator()

    init() {
        workspaceManager = FileWorkspaceManager()
        rootURL = workspaceManager.rootURL
        reload()
    }

    var totalCount: Int { items.count }
    var totalFolders: Int { items.filter(\.isDirectory).count }
    var totalFiles: Int { items.filter { !$0.isDirectory }.count }
    var totalBytes: Int64 { items.reduce(0) { $0 + $1.size } }

    func reload() {
        items = metadataService.listItems(in: rootURL)
    }

    func createFolder(name: String) {
        let safeName = fileNameValidator.sanitize(name)
        guard !safeName.isEmpty else { return }
        let folderURL = workspaceManager.uniqueURL(for: safeName)
        try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        reload()
    }

    func createFile(name: String, type: ManagedFileType, content: String = "") {
        let safeName = fileNameValidator.sanitize(name)
        guard !safeName.isEmpty else { return }
        let fileURL = workspaceManager.uniqueURL(for: safeName, fileExtension: type.rawValue)
        try? content.data(using: .utf8)?.write(to: fileURL)
        reload()
    }

    func createFromTemplate(_ template: FileTemplate) {
        let fileURL = workspaceManager.uniqueURL(for: template.fileName)
        try? template.contents.data(using: .utf8)?.write(to: fileURL)
        reload()
    }

    func importFiles(urls: [URL]) {
        for url in urls {
            let target = workspaceManager.uniqueURL(for: url.lastPathComponent)
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
