import Foundation

class SemanticSearchService {
    static let shared = SemanticSearchService()

    private init() {}

    func search(query: String) async -> [WorkspaceEntity] {
        let embedding = await EmbeddingService.shared.generateEmbedding(for: query)
        // In a real implementation, we'd compare this against indexed entity embeddings
        return await UnifiedDataStore.shared.entities.filter { entity in
            // Mocking high relevance for demo
            entity.title.localizedCaseInsensitiveContains(query)
        }
    }
}
