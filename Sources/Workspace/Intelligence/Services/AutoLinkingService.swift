import Foundation

class AutoLinkingService {
    static let shared = AutoLinkingService()

    private init() {}

    func discoverLinks(for entity: WorkspaceEntity) async -> [WorkspaceEntity] {
        // Link based on semantic similarity or shared keywords
        return await UnifiedDataStore.shared.entities.filter { other in
            other.id != entity.id && (other.title.contains(entity.title) || entity.title.contains(other.title))
        }
    }
}
