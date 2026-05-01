import Foundation

/// Logic for advanced, semantic searching across collaboration spaces.
final class CollaborationSearchEngine: ObservableObject {
    static let shared = CollaborationSearchEngine()

    struct SearchResult: Identifiable {
        let id = UUID()
        let objectID: UUID
        let type: CollaborationFramework.WorkspaceObjectType
        let title: String
        let snippet: String
        let score: Double
    }

    private init() {}

    /// Performs a semantic search across all indexed spaces and objects.
    func search(query: String, filter: SearchFilter) -> [SearchResult] {
        let normalizedQuery = query.lowercased()
        var results: [SearchResult] = []

        // Scan all indexed objects (in a real app, this would query a search index)
        for (id, type) in CollaborationFramework.shared.indexedObjects {
            // Filter by type
            if !filter.types.isEmpty && !filter.types.contains(type) { continue }

            // Mock matching against some titles/content
            let mockTitle = "\(type.rawValue.capitalized) \(id.uuidString.prefix(4))"
            if mockTitle.lowercased().contains(normalizedQuery) {
                results.append(SearchResult(
                    objectID: id,
                    type: type,
                    title: mockTitle,
                    snippet: "Found matching content in \(type.rawValue)...",
                    score: 1.0
                ))
            }
        }

        return results.sorted { $0.score > $1.score }
    }

    struct SearchFilter {
        var types: Set<CollaborationFramework.WorkspaceObjectType> = []
        var authorID: UUID?
        var dateRange: ClosedRange<Date>?
        var includeForks: Bool = true
    }
}
