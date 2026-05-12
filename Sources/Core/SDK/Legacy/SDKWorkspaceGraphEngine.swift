import Foundation

public final class SDKWorkspaceGraphEngine {
    nonisolated(unsafe) public static let shared = SDKWorkspaceGraphEngine()

    private let persistenceURL: URL
    private var nodes: [SDKNode] = []
    private var edges: [SDKEdge] = []

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        persistenceURL = appSupport.appendingPathComponent("sdk_workspace_graph.json")

        if !FileManager.default.fileExists(atPath: appSupport.path) {
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }

        loadGraph()
    }

    public func fetchGraph() -> SDKGraph {
        refreshFromWorkspace()
        return SDKGraph(nodes: nodes, edges: edges)
    }

    public func updateLink(source: UUID, target: UUID, relation: String) {
        let existingEdge = edges.first { $0.source == source && $0.target == target && $0.label == relation }
        guard existingEdge == nil else { return }

        edges.append(SDKEdge(source: source, target: target, label: relation))
        persistGraph()

        Task { @MainActor in SDKLogStore.shared.log("Graph link updated: \(source) -[\(relation)]-> \(target)", source: "SDKWorkspaceGraphEngine", level: LogLevel.info) }
    }

    public func removeLink(source: UUID, target: UUID) {
        edges.removeAll { $0.source == source && $0.target == target }
        persistGraph()
    }

    public func addNode(_ node: SDKNode) {
        guard !nodes.contains(where: { $0.id == node.id }) else { return }
        nodes.append(node)
        persistGraph()
    }

    public func removeNode(id: UUID) {
        nodes.removeAll { $0.id == id }
        edges.removeAll { $0.source == id || $0.target == id }
        persistGraph()
    }

    private func refreshFromWorkspace() {
        let tasks = WorkspaceAPI.shared.tasks.listTasks()
        for task in tasks where !nodes.contains(where: { $0.id == task.id }) {
            nodes.append(SDKNode(id: task.id, label: task.title, type: "task"))
        }

        let notes = WorkspaceAPI.shared.notes.listNotes()
        for note in notes where !nodes.contains(where: { $0.id == note.id }) {
            nodes.append(SDKNode(id: note.id, label: note.title, type: "note"))
        }

        let decks = WorkspaceAPI.shared.slides.listDecks()
        for deck in decks where !nodes.contains(where: { $0.id == deck.id }) {
            nodes.append(SDKNode(id: deck.id, label: deck.title, type: "slide"))
        }
    }

    private func persistGraph() {
        struct GraphData: Codable, Sendable {
            let nodes: [NodeData]
            let edges: [EdgeData]

            struct NodeData: Codable, Sendable { let id: UUID; let label: String; let type: String }
            struct EdgeData: Codable, Sendable { let source: UUID; let target: UUID; let label: String }
        }

        let data = GraphData(
            nodes: nodes.map { GraphData.NodeData(id: $0.id, label: $0.label, type: $0.type) },
            edges: edges.map { GraphData.EdgeData(source: $0.source, target: $0.target, label: $0.label) }
        )

        if let encoded = try? JSONEncoder().encode(data) {
            try? encoded.write(to: persistenceURL)
        }
    }

    private func loadGraph() {
        struct GraphData: Codable, Sendable {
            let nodes: [NodeData]
            let edges: [EdgeData]

            struct NodeData: Codable, Sendable { let id: UUID; let label: String; let type: String }
            struct EdgeData: Codable, Sendable { let source: UUID; let target: UUID; let label: String }
        }

        guard let data = try? Data(contentsOf: persistenceURL),
              let decoded = try? JSONDecoder().decode(GraphData.self, from: data) else { return }

        nodes = decoded.nodes.map { SDKNode(id: $0.id, label: $0.label, type: $0.type) }
        edges = decoded.edges.map { SDKEdge(source: $0.source, target: $0.target, label: $0.label) }
    }
}

public struct SDKGraph: Sendable {
    public let nodes: [SDKNode]
    public let edges: [SDKEdge]
}

public struct SDKNode: Identifiable, Sendable {
    public let id: UUID
    public let label: String
    public let type: String
}

public struct SDKEdge: Identifiable, Sendable {
    public let id = UUID()
    public let source: UUID
    public let target: UUID
    public let label: String
}
