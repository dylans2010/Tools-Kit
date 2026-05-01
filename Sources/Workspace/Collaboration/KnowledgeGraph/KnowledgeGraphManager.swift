import Foundation

/// Node in the knowledge graph.
struct GraphNode: Identifiable, Codable {
    let id: UUID
    let label: String
    let type: String
}

/// Edge in the knowledge graph.
struct GraphEdge: Identifiable, Codable {
    let id: UUID
    let sourceID: UUID
    let targetID: UUID
    let relationship: String
}

/// Manages the visualization and data for the interactive workspace graph.
final class KnowledgeGraphManager: ObservableObject {
    static let shared = KnowledgeGraphManager()

    @Published var nodes: [GraphNode] = []
    @Published var edges: [GraphEdge] = []

    private init() {}

    /// Builds the graph for a specific space.
    func buildGraph(for spaceID: UUID) {
        // Logic to fetch all linked objects and their relationships
    }
}
