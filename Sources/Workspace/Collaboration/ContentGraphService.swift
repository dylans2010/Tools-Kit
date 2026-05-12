import Foundation
import Combine

/// Graph-based content structure: nodes are notes/tasks/files, edges are relationships.
final class ContentGraphService: ObservableObject {
    static let shared = ContentGraphService()

    // MARK: - Models

    enum NodeType: String, Codable, CaseIterable, Sendable {
        case note = "Note"
        case task = "Task"
        case file = "File"
        case decision = "Decision"
        case member = "Member"
    }

    enum EdgeType: String, Codable, CaseIterable, Sendable {
        case reference = "References"
        case dependency = "Depends On"
        case relatedTo = "Related To"
        case blockedBy = "Blocked By"
        case assignedTo = "Assigned To"
    }

    struct ContentNode: Codable, Identifiable, Sendable {
        let id: UUID
        var label: String
        var nodeType: NodeType
        var metadata: [String: String]
        var tags: [String]
        var createdAt: Date
    }

    struct ContentEdge: Codable, Identifiable, Sendable {
        let id: UUID
        var sourceID: UUID
        var targetID: UUID
        var edgeType: EdgeType
        var weight: Double
    }

    // MARK: - State

    @Published private(set) var nodes: [ContentNode] = []
    @Published private(set) var edges: [ContentEdge] = []

    private let nodesFile = "content_graph_nodes.json"
    private let edgesFile = "content_graph_edges.json"

    private init() {
        loadData()
    }

    // MARK: - Node Operations

    @discardableResult
    func addNode(label: String, type: NodeType, metadata: [String: String] = [:], tags: [String] = []) -> ContentNode {
        let node = ContentNode(id: UUID(), label: label, nodeType: type, metadata: metadata, tags: tags, createdAt: Date())
        nodes.append(node)
        saveData()
        return node
    }

    func updateNode(id: UUID, label: String? = nil, tags: [String]? = nil, metadata: [String: String]? = nil) {
        guard let index = nodes.firstIndex(where: { $0.id == id }) else { return }
        if let label = label { nodes[index].label = label }
        if let tags = tags { nodes[index].tags = tags }
        if let metadata = metadata {
            for (k, v) in metadata { nodes[index].metadata[k] = v }
        }
        saveData()
    }

    func removeNode(id: UUID) {
        nodes.removeAll { $0.id == id }
        edges.removeAll { $0.sourceID == id || $0.targetID == id }
        saveData()
    }

    // MARK: - Edge Operations

    @discardableResult
    func linkNodes(source: UUID, target: UUID, type: EdgeType, weight: Double = 1.0) -> ContentEdge {
        // Prevent duplicate edges of same type
        if let existing = edges.first(where: { $0.sourceID == source && $0.targetID == target && $0.edgeType == type }) {
            return existing
        }
        let edge = ContentEdge(id: UUID(), sourceID: source, targetID: target, edgeType: type, weight: weight)
        edges.append(edge)
        saveData()
        return edge
    }

    func removeEdge(id: UUID) {
        edges.removeAll { $0.id == id }
        saveData()
    }

    // MARK: - Query

    func neighbors(of nodeID: UUID) -> [ContentNode] {
        let connected = edges
            .filter { $0.sourceID == nodeID || $0.targetID == nodeID }
            .flatMap { [$0.sourceID, $0.targetID] }
            .filter { $0 != nodeID }
        return nodes.filter { connected.contains($0.id) }
    }

    func edges(for nodeID: UUID) -> [ContentEdge] {
        edges.filter { $0.sourceID == nodeID || $0.targetID == nodeID }
    }

    func search(query: String) -> [ContentNode] {
        let q = query.lowercased()
        return nodes.filter {
            $0.label.lowercased().contains(q) ||
            $0.tags.contains(where: { $0.lowercased().contains(q) }) ||
            $0.metadata.values.contains(where: { $0.lowercased().contains(q) })
        }
    }

    func nodes(ofType type: NodeType) -> [ContentNode] {
        nodes.filter { $0.nodeType == type }
    }

    // MARK: - Persistence

    private func saveData() {
        let n = nodes; let e = edges
        DispatchQueue.global(qos: .utility).async {
            try? WorkspacePersistence.shared.save(n, to: self.nodesFile)
            try? WorkspacePersistence.shared.save(e, to: self.edgesFile)
        }
    }

    private func loadData() {
        if WorkspacePersistence.shared.exists(filename: nodesFile) {
            nodes = (try? WorkspacePersistence.shared.load([ContentNode].self, from: nodesFile)) ?? []
        }
        if WorkspacePersistence.shared.exists(filename: edgesFile) {
            edges = (try? WorkspacePersistence.shared.load([ContentEdge].self, from: edgesFile)) ?? []
        }
    }
}
