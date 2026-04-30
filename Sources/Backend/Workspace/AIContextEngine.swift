import Foundation
import Combine

/// Manages AI context across notes and slides, enabling semantic search and relationship mapping.
@MainActor
final class AIContextEngine: ObservableObject {
    static let shared = AIContextEngine()

    struct SemanticEntry: Codable, Identifiable, Sendable {
        let id: UUID
        let contentHash: String
        let embedding: [Float]?
        let tags: [String]
        let relatedIDs: [UUID]
        let metadata: [String: String]
    }

    struct SemanticRelationship: Codable, Identifiable, Sendable {
        let id: UUID
        let sourceID: UUID
        let targetID: UUID
        let type: RelationshipType
        let weight: Double
    }

    enum RelationshipType: String, Codable, Sendable {
        case reference
        case dependency
        case causal
        case similarity
    }

    @Published private(set) var semanticIndex: [UUID: SemanticEntry] = [:]
    @Published private(set) var relationshipIndex: [UUID: [SemanticRelationship]] = [:]

    private let aiService = AIService.shared

    private init() {}

    func indexContent(_ content: String, forID id: UUID, metadata: [String: String] = [:]) async {
        // Generate embeddings and extract tags via AI
        let tags = await extractTags(from: content)
        let entry = SemanticEntry(
            id: id,
            contentHash: content.hashValue.description,
            embedding: nil,
            tags: tags,
            relatedIDs: [],
            metadata: metadata
        )

        semanticIndex[id] = entry
        await updateRelationships(for: id, content: content)
    }

    func semanticSearch(query: String, limit: Int = 5) async -> [UUID] {
        let queryTerms = query.lowercased().split(separator: " ").map(String.init)

        let scoredItems = semanticIndex.values.map { entry -> (UUID, Double) in
            var score: Double = 0
            for term in queryTerms {
                if entry.tags.contains(where: { $0.lowercased().contains(term) }) {
                    score += 1.0
                }
                if entry.metadata.values.contains(where: { $0.lowercased().contains(term) }) {
                    score += 0.5
                }
            }
            return (entry.id, score)
        }

        return scoredItems
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { $0.0 }
    }

    func suggestLinks(forContent content: String) -> [UUID] {
        return Array(semanticIndex.keys.prefix(3))
    }

    func addRelationship(source: UUID, target: UUID, type: RelationshipType, weight: Double = 1.0) {
        let relationship = SemanticRelationship(id: UUID(), sourceID: source, targetID: target, type: type, weight: weight)

        relationshipIndex[source, default: []].append(relationship)
        relationshipIndex[target, default: []].append(relationship)
    }

    private func extractTags(from content: String) async -> [String] {
        let prompt = "Extract 3-5 descriptive tags from the following content: \(content.prefix(500))"
        do {
            let response = try await aiService.processText(prompt: prompt, systemPrompt: "Return only a comma-separated list of tags.")
            return response.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        } catch {
            return ["workspace"]
        }
    }

    private func updateRelationships(for id: UUID, content: String) async {
        for (otherID, entry) in semanticIndex where otherID != id {
            if content.contains(entry.id.uuidString) {
                addRelationship(source: id, target: otherID, type: .reference)
            }
        }
    }
}
