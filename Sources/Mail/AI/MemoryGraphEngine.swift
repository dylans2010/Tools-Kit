import Foundation

/// Engine managing a persistent graph of communication history, relationships, and context recall.
actor MemoryGraphEngine {
    static let shared = MemoryGraphEngine()
    private var nodes: [UUID: MemoryGraphNode] = [:]
    private var edges: [MemoryGraphEdge] = []

    private init() {
        Task { await loadGraph() }
    }

    /// Adds or updates a node in the graph.
    func recordInteraction(node: MemoryGraphNode) {
        nodes[node.id] = node
        saveGraph()
    }

    /// Links two nodes in the graph.
    func linkNodes(sourceID: UUID, targetID: UUID, relationship: String, strength: Double = 1.0) {
        let edge = MemoryGraphEdge(id: UUID(), sourceID: sourceID, targetID: targetID, relationshipType: relationship, strength: strength)
        edges.append(edge)
        saveGraph()
    }

    /// Recalls context related to a specific value or topic.
    func recallContext(for value: String) -> [MemoryGraphNode] {
        return nodes.values.filter { $0.value.localizedCaseInsensitiveContains(value) }
    }

    /// Returns related nodes for a given node ID.
    func getRelatedNodes(for nodeID: UUID) -> [MemoryGraphNode] {
        let relatedIDs = edges
            .filter { $0.sourceID == nodeID || $0.targetID == nodeID }
            .map { $0.sourceID == nodeID ? $0.targetID : $0.sourceID }
        return relatedIDs.compactMap { nodes[$0] }
    }

    private var storageURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("mail_memory_graph.json")
    }

    private struct GraphData: Codable {
        let nodes: [UUID: MemoryGraphNode]
        let edges: [MemoryGraphEdge]
    }

    private func loadGraph() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode(GraphData.self, from: data) else { return }
        self.nodes = decoded.nodes
        self.edges = decoded.edges
    }

    private func saveGraph() {
        let data = GraphData(nodes: nodes, edges: edges)
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        try? encoded.write(to: storageURL)
    }
}
