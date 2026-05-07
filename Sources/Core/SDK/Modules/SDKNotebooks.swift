import Foundation

/// SDKNotebooks: Manages documents and notebooks within the WorkspaceSDK.
public final class SDKNotebooks {
    public static let shared = SDKNotebooks()

    private let dataStore = SDKDataStore.shared
    private let collection = "notebook_pages"

    public struct Page: SDKModel {
        public let id: UUID
        public let title: String
        public let content: String
        public let createdAt: Date
        public var updatedAt: Date
        public var version: Int

        public init(id: UUID = UUID(), title: String, content: String, version: Int = 1, createdAt: Date = Date(), updatedAt: Date = Date()) {
            self.id = id
            self.title = title
            self.content = content
            self.version = version
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    private init() {
        registerEndpoints()
    }

    private func registerEndpoints() {
        SDKRouter.shared.register(endpoint: "notes.create") { request in
            guard let title = request.parameters["title"] as? String,
                  let content = request.parameters["content"] as? String else {
                throw SDKNotebookError.invalidParameters
            }
            return try await self.createNote(title: title, content: content)
        }

        SDKRouter.shared.register(endpoint: "notes.list") { _ in
            return try self.listNotes()
        }
    }

    public func createNote(title: String, content: String) async throws -> Page {
        try SDKPermissionManager.shared.enforce(scope: .notebooksWrite)

        let page = Page(title: title, content: content)
        try dataStore.save(page, in: collection)

        SDKEventBus.shared.publish(SDKEvent(type: "note.created", source: "SDKNotebooks", payload: ["title": title]))
        return page
    }

    public func listNotes() throws -> [Page] {
        try SDKPermissionManager.shared.enforce(scope: .notebooksRead)
        return try dataStore.fetchAll(in: collection)
    }

    public func updateNote(id: UUID, title: String, content: String) async throws -> Page {
        try SDKPermissionManager.shared.enforce(scope: .notebooksWrite)

        guard var page = try dataStore.fetch(id: id, in: collection) as Page? else {
            throw SDKNotebookError.notFound
        }

        page = Page(id: id, title: title, content: content, version: page.version + 1, createdAt: page.createdAt, updatedAt: Date())
        try dataStore.save(page, in: collection)

        SDKEventBus.shared.publish(SDKEvent(type: "note.updated", source: "SDKNotebooks", payload: ["id": id.uuidString]))
        return page
    }
}

public enum SDKNotebookError: Error {
    case invalidParameters
    case notFound
}
