import Foundation
import Combine

/// The central source of truth for all ToolsKit data.
/// Handles persistent storage, in-memory caching, and change notifications.
final class UnifiedDataStore: ObservableObject {
    static let shared = UnifiedDataStore()

    @Published private(set) var workflows: [WorkspaceWorkflow] = []
    @Published private(set) var canvases: [SpatialCanvas] = []

    private let persistence = WorkspacePersistence.shared
    private let eventBus = PluginEventBus.shared

    private init() {
        self.workflows = loadWorkflowsFromDisk()
        self.canvases = loadCanvasesFromDisk()
    }

    // MARK: - Specialized Storage

    func saveWorkflows(_ workflows: [WorkspaceWorkflow]) throws {
        self.workflows = workflows
        try save(workflows, key: "workspace_workflows")
    }

    func loadWorkflows() -> [WorkspaceWorkflow] {
        return workflows
    }

    private func loadWorkflowsFromDisk() -> [WorkspaceWorkflow] {
        return (try? load([WorkspaceWorkflow].self, key: "workspace_workflows")) ?? []
    }

    func saveCanvas(_ canvas: SpatialCanvas) throws {
        if let index = canvases.firstIndex(where: { $0.id == canvas.id }) {
            canvases[index] = canvas
        } else {
            canvases.append(canvas)
        }
        try save(canvases, key: "spatial_canvases")
    }

    func loadCanvases() -> [SpatialCanvas] {
        return canvases
    }

    private func loadCanvasesFromDisk() -> [SpatialCanvas] {
        return (try? load([SpatialCanvas].self, key: "spatial_canvases")) ?? []
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
