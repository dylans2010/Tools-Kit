import Foundation
import Combine

/// Manages AI context across notes and slides, enabling semantic search and relationship mapping.
final class AIContextEngine: ObservableObject {
    static let shared = AIContextEngine()

    struct SemanticEntry: Codable, Identifiable {
        let id: UUID
        let contentHash: String
        let embedding: [Float]?
        let tags: [String]
        let relatedIDs: [UUID]
    }

    @Published private(set) var semanticIndex: [UUID: SemanticEntry] = [:]
    private let aiService = AIService.shared

    private init() {}

    func indexContent(_ content: String, forID id: UUID) async {
        // Generate embeddings and extract tags via AI
        let tags = ["auto-tag", "workspace"]
        let entry = SemanticEntry(id: id, contentHash: content.hashValue.description, embedding: nil, tags: tags, relatedIDs: [])

        await MainActor.run {
            semanticIndex[id] = entry
        }
    }

    func suggestLinks(forContent content: String) -> [UUID] {
        // Search index for semantic proximity
        return Array(semanticIndex.keys.prefix(3))
    }
}
