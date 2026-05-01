import Foundation

protocol WorkspaceToolPlugin {
    var id: String { get }
    var name: String { get }
    func validate(context: WorkspaceActionContext) throws
    func execute(context: WorkspaceActionContext) async throws -> WorkspaceActionResult
}

struct WorkspaceActionContext {
    let spaceID: UUID
    let actorID: UUID
    let payload: [String: String]
}

struct WorkspaceActionResult {
    let actionID: UUID
    let summary: String
    let timestamp: Date
}

final class ToolRegistry {
    static let shared = ToolRegistry()
    private var plugins: [String: WorkspaceToolPlugin] = [:]
    private let lock = NSLock()

    private init() {}

    func register(_ plugin: WorkspaceToolPlugin) {
        lock.lock(); defer { lock.unlock() }
        plugins[plugin.id] = plugin
    }

    func plugin(named id: String) -> WorkspaceToolPlugin? {
        lock.lock(); defer { lock.unlock() }
        return plugins[id]
    }

    func allTools() -> [WorkspaceToolPlugin] {
        lock.lock(); defer { lock.unlock() }
        return Array(plugins.values).sorted { $0.name < $1.name }
    }
}
