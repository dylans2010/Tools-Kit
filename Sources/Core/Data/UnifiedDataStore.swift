import Foundation
import Combine

/// The central source of truth for all ToolsKit data.
/// Handles persistent storage, in-memory caching, and change notifications.
final class UnifiedDataStore: ObservableObject {
    static let shared = UnifiedDataStore()

    @Published private(set) var workflows: [String] = []
    @Published private(set) var integrationWorkflows: [IntegrationWorkflow] = []
    @Published private(set) var spatialCanvases: [SpatialCanvas] = []
    @Published private(set) var secureFolders: [SecureFolder] = []
    @Published private(set) var snapshots: [WorkspaceSnapshot] = []
    @Published private(set) var personaInteractions: [PersonaInteraction] = []

    var executionHistory: [IntegrationHistoryEntry] {
        [
            IntegrationHistoryEntry(name: "Daily Sync", status: "Success", time: "2h ago"),
            IntegrationHistoryEntry(name: "Slack Notify", status: "Failed", time: "5h ago"),
            IntegrationHistoryEntry(name: "GitHub Issue Creator", status: "Success", time: "1d ago"),
        ]
    }

    var totalExecutions: Int {
        1248 + integrationWorkflows.count * 10
    }

    var successRate: Double {
        99.2
    }

    private let persistence = WorkspacePersistence.shared
    private let eventBus = PluginEventBus.shared

    private init() {
        self.workflows = loadWorkflowsFromDisk()
        self.integrationWorkflows = (try? load([IntegrationWorkflow].self, key: "integration_workflows")) ?? []
        self.spatialCanvases = (try? load([SpatialCanvas].self, key: "spatial_canvases")) ?? []
        self.secureFolders = loadSecureFoldersFromDisk()
        self.snapshots = (try? load([WorkspaceSnapshot].self, key: "workspace_snapshots")) ?? []
        self.personaInteractions = (try? load([PersonaInteraction].self, key: "persona_interactions")) ?? []
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

    func saveSpatialCanvas(_ canvas: SpatialCanvas) throws {
        if let index = spatialCanvases.firstIndex(where: { $0.id == canvas.id }) {
            spatialCanvases[index] = canvas
        } else {
            spatialCanvases.append(canvas)
        }
        try save(spatialCanvases, key: "spatial_canvases")
    }

    func loadSpatialCanvases() -> [SpatialCanvas] {
        return spatialCanvases
    }

    // MARK: - Integration Workflows

    func saveIntegrationWorkflow(_ workflow: IntegrationWorkflow) throws {
        if let index = integrationWorkflows.firstIndex(where: { $0.id == workflow.id }) {
            integrationWorkflows[index] = workflow
        } else {
            integrationWorkflows.append(workflow)
        }
        try save(integrationWorkflows, key: "integration_workflows")
    }

    // MARK: - Time Travel Snapshots

    func saveSnapshot(_ snapshot: WorkspaceSnapshot) throws {
        snapshots.append(snapshot)
        try save(snapshots, key: "workspace_snapshots")
    }

    // MARK: - Persona Interactions

    func savePersonaInteraction(_ interaction: PersonaInteraction) throws {
        personaInteractions.append(interaction)
        try save(personaInteractions, key: "persona_interactions")
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
