import Foundation

@MainActor
class UnifiedDataStore: ObservableObject {
    static let shared = UnifiedDataStore()

    @Published var entities: [WorkspaceEntity] = []

    private init() {
        loadData()
    }

    private func loadData() {
        // Load from WorkspacePersistence if available
    }

    func addEntity(_ entity: WorkspaceEntity) {
        entities.append(entity)
    }

    func search(query: String) -> [WorkspaceEntity] {
        return entities.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }
}

struct WorkspaceEntity: Identifiable, Codable {
    let id: UUID
    let title: String
    let type: EntityType
    let content: String
    let metadata: [String: String]

    enum EntityType: String, Codable {
        case note, task, email, calendar, file, whiteboard
    }
}
