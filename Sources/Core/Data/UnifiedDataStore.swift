import Foundation
import Combine

/// The central source of truth for all ToolsKit data.
/// Handles persistent storage, in-memory caching, and change notifications.
final class UnifiedDataStore: ObservableObject {
    static let shared = UnifiedDataStore()

    @Published private(set) var workflows: [String] = []
    @Published private(set) var canvases: [String] = []
    @Published private(set) var secureFolders: [SecureFolder] = []

    private let persistence = WorkspacePersistence.shared
    private let eventBus = PluginEventBus.shared

    private init() {
        self.workflows = loadWorkflowsFromDisk()
        self.canvases = loadCanvasesFromDisk()
        self.secureFolders = loadSecureFoldersFromDisk()
    }

    // MARK: - Specialized Storage

    func saveWorkflows(_ workflows: [String]) throws {
        self.workflows = workflows
        try save(workflows, key: "workspace_workflows")
    }

    func loadWorkflows() -> [String] {
        return workflows
    }

    private func loadWorkflowsFromDisk() -> [String] {
        return (try? load([String].self, key: "workspace_workflows")) ?? []
    }

    func saveCanvas(_ canvas: String) throws {
        if !canvases.contains(canvas) {
            canvases.append(canvas)
        }
        try save(canvases, key: "spatial_canvases")
    }

    func loadCanvases() -> [String] {
        return canvases
    }

    private func loadCanvasesFromDisk() -> [String] {
        return (try? load([String].self, key: "spatial_canvases")) ?? []
    }

    // MARK: - Secure Folders

    func saveSecureFolders(_ folders: [SecureFolder]) throws {
        self.secureFolders = folders
        try save(folders, key: "secure_folders")
    }

    func loadSecureFolders() -> [SecureFolder] {
        return secureFolders
    }

    private func loadSecureFoldersFromDisk() -> [SecureFolder] {
        return (try? load([SecureFolder].self, key: "secure_folders")) ?? []
    }

    // MARK: - Generic Persistence

    func save<T: Encodable>(_ object: T, key: String) throws {
        try persistence.save(object, to: "\(key).json")

        let event = PluginEvent(
            id: UUID(),
            capability: .intelligence,
            action: "data.updated",
            payload: ["key": key],
            timestamp: Date()
        )
        eventBus.emit(event)
    }

    func load<T: Decodable>(_ type: T.Type, key: String) throws -> T {
        return try persistence.load(type, from: "\(key).json")
    }

    func exists(key: String) -> Bool {
        return persistence.exists(filename: "\(key).json")
    }

    func delete(key: String) throws {
        try persistence.delete(filename: "\(key).json")
    }
}
