import Foundation
import Combine

/// Protocol for the SDK notebook service.
@MainActor
public protocol SDKNotebookServiceProtocol {
    func createNotebook(title: String) throws -> SDKNotebook
    func listNotebooks() -> [SDKNotebook]
    func getNotebook(id: UUID) -> SDKNotebook?
    func deleteNotebook(id: UUID) throws
    func searchNotebooks(query: String) -> [SDKNotebook]
}

/// Full SDK Notebooks module — handles document management, version history, and persistence.
@MainActor
public final class SDKNotebookService: SDKNotebookServiceProtocol, ObservableObject {
    public static let shared = SDKNotebookService()

    @Published public private(set) var notebooks: [SDKNotebook] = []

    private let dataStore = SDKDataStore.shared
    private let queryEngine = SDKQueryEngine.self

    private init() {}

    public func initialize() {
        loadFromStore()
        syncFromWorkspace()
    }

    // MARK: - Create

    public func createNotebook(title: String) throws -> SDKNotebook {
        guard SDKPermissionManager.shared.isScopeAuthorized("notebooks.write") else {
            throw SDKError.permissionDenied(scope: "notebooks.write")
        }

        var notebook = SDKNotebook(title: title)
        let defaultPage = SDKNotebookPage(title: "Welcome Page", content: "Start writing here...")
        notebook.pages = [defaultPage]

        try dataStore.save(notebook)
        notebooks.insert(notebook, at: 0)

        // Sync to workspace legacy store
        let page = NotebookPage(id: defaultPage.id, title: defaultPage.title, content: defaultPage.content, createdAt: defaultPage.createdAt, updatedAt: defaultPage.updatedAt)
        if let firstNotebook = NotebooksManager.shared.notebooks.first,
           let firstFolder = firstNotebook.folders.first {
            var folder = firstFolder
            folder.pages.append(page)
            NotebooksManager.shared.updateFolder(folder, in: firstNotebook)
        }

        SDKEventBus.shared.publish(SDKBusEvent(channel: "notebooks", name: "notebook.created", data: ["id": notebook.id.uuidString, "title": title]))
        Task { await SDKLogStore.shared.log("Notebook created: \(title)", source: "SDKNotebookService", level: .info) }
        return notebook
    }

    // MARK: - Read

    public func listNotebooks() -> [SDKNotebook] {
        return queryEngine.sort(notebooks, by: \.updatedAt, order: .descending)
    }

    public func getNotebook(id: UUID) -> SDKNotebook? {
        return notebooks.first { $0.id == id }
    }

    // MARK: - Update

    public func updateNotebook(id: UUID, title: String? = nil, tags: [String]? = nil) throws {
        guard let index = notebooks.firstIndex(where: { $0.id == id }) else { return }
        if let title = title { notebooks[index].title = title }
        if let tags = tags { notebooks[index].tags = tags }
        notebooks[index].updatedAt = Date()
        try dataStore.save(notebooks[index])

        SDKEventBus.shared.publish(SDKBusEvent(channel: "notebooks", name: "notebook.updated", data: ["id": id.uuidString]))
    }

    // MARK: - Pages

    public func addPage(to notebookId: UUID, title: String, content: String = "") throws -> SDKNotebookPage {
        guard let index = notebooks.firstIndex(where: { $0.id == notebookId }) else {
            throw SDKError.executionFailed(reason: "Notebook not found")
        }
        let page = SDKNotebookPage(title: title, content: content)
        notebooks[index].pages.append(page)
        notebooks[index].updatedAt = Date()
        try dataStore.save(notebooks[index])

        SDKEventBus.shared.publish(SDKBusEvent(channel: "notebooks", name: "page.created", data: ["notebookId": notebookId.uuidString, "pageId": page.id.uuidString]))
        return page
    }

    public func updatePage(in notebookId: UUID, pageId: UUID, content: String) throws {
        guard let nbIndex = notebooks.firstIndex(where: { $0.id == notebookId }),
              let pgIndex = notebooks[nbIndex].pages.firstIndex(where: { $0.id == pageId }) else { return }

        // Persistent Version History
        let currentContent = notebooks[nbIndex].pages[pgIndex].content
        if currentContent != content {
            let versionNumber = notebooks[nbIndex].pages[pgIndex].versionHistory.count + 1
            let version = SDKPageVersion(content: currentContent, versionNumber: versionNumber)
            notebooks[nbIndex].pages[pgIndex].versionHistory.append(version)

            notebooks[nbIndex].pages[pgIndex].content = content
            notebooks[nbIndex].pages[pgIndex].updatedAt = Date()
            notebooks[nbIndex].updatedAt = Date()
            try dataStore.save(notebooks[nbIndex])

            SDKEventBus.shared.publish(SDKBusEvent(channel: "notebooks", name: "page.updated", data: ["pageId": pageId.uuidString]))
        }
    }

    // MARK: - Search

    public func searchNotebooks(query: String) -> [SDKNotebook] {
        if query.isEmpty { return notebooks }
        let lowered = query.lowercased()

        return queryEngine.filter(notebooks) { notebook in
            notebook.title.lowercased().contains(lowered) ||
            notebook.tags.contains { $0.lowercased().contains(lowered) } ||
            notebook.pages.contains { $0.title.lowercased().contains(lowered) || $0.content.lowercased().contains(lowered) }
        }
    }

    // MARK: - Delete

    public func deleteNotebook(id: UUID) throws {
        try dataStore.delete(SDKNotebook.self, id: id)
        notebooks.removeAll { $0.id == id }
        SDKEventBus.shared.publish(SDKBusEvent(channel: "notebooks", name: "notebook.deleted", data: ["id": id.uuidString]))
    }

    // MARK: - Private

    private func loadFromStore() {
        notebooks = dataStore.fetchAll(SDKNotebook.self)
    }

    private func syncFromWorkspace() {
        let workspaceNotebooks = NotebooksManager.shared.notebooks
        var added = false
        for wb in workspaceNotebooks {
            let exists = notebooks.contains { $0.title == wb.name }
            if !exists {
                let pages = wb.folders.flatMap { $0.pages }.map { page in
                    SDKNotebookPage(id: page.id, title: page.title, content: page.content)
                }
                let sdkNotebook = SDKNotebook(title: wb.name, pages: pages)
                try? dataStore.save(sdkNotebook)
                notebooks.append(sdkNotebook)
                added = true
            }
        }
        if added {
            notebooks.sort { $0.updatedAt > $1.updatedAt }
        }
    }
}
