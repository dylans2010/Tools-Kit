import Foundation

@MainActor
class ContextGraphManager: ObservableObject {
    static let shared = ContextGraphManager()

    @Published var relationships: [UUID: [UUID]] = [:]

    private init() {}

    func addRelationship(from: UUID, to: UUID) {
        var links = relationships[from] ?? []
        if !links.contains(to) {
            links.append(to)
            relationships[from] = links
        }
    }

    func getRelatedEntities(for entityID: UUID) -> [WorkspaceEntity] {
        let relatedIDs = relationships[entityID] ?? []
        return UnifiedDataStore.shared.entities.filter { relatedIDs.contains($0.id) }
    }
}
