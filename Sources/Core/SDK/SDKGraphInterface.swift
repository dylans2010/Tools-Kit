import Foundation
import Combine

@MainActor
public final class SDKGraphInterface: ObservableObject {
    public static let shared = SDKGraphInterface()

    @Published public var graph = SDKGraph(nodes: [], edges: [])

    private let persistenceURL: URL
    private let queue = DispatchQueue(label: "com.toolskit.sdk.graph", qos: .utility)

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        persistenceURL = appSupport.appendingPathComponent("sdk_graph.json")

        if !FileManager.default.fileExists(atPath: appSupport.path) {
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }

        loadGraph()
        buildGraphFromWorkspace()
    }

    // MARK: - Query

    public func query(entityType: String?, relation: String?) -> SDKGraph {
        var filteredNodes = graph.nodes
        var filteredEdges = graph.edges

        if let entityType = entityType {
            filteredNodes = filteredNodes.filter { $0.type == entityType }
            let nodeIDs = Set(filteredNodes.map(\.id))
            filteredEdges = filteredEdges.filter { nodeIDs.contains($0.source) || nodeIDs.contains($0.target) }
        }

        if let relation = relation {
            filteredEdges = filteredEdges.filter { $0.label == relation }
        }

        return SDKGraph(nodes: filteredNodes, edges: filteredEdges)
    }

    // MARK: - Link Entities

    public func linkEntities(source: UUID, target: UUID, relation: String) {
        let existingEdge = graph.edges.first { $0.source == source && $0.target == target && $0.label == relation }
        guard existingEdge == nil else { return }

        let edge = SDKEdge(source: source, target: target, label: relation)
        graph = SDKGraph(nodes: graph.nodes, edges: graph.edges + [edge])

        SDKWorkspaceGraphEngine.shared.updateLink(source: source, target: target, relation: relation)
        persistGraph()

        SDKLogStore.shared.log("Graph link created: \(source) -[\(relation)]-> \(target)", source: "SDKGraphInterface", level: .info)
    }

    // MARK: - Add Node

    public func addNode(label: String, type: String) -> SDKNode {
        let node = SDKNode(id: UUID(), label: label, type: type)
        graph = SDKGraph(nodes: graph.nodes + [node], edges: graph.edges)
        persistGraph()
        return node
    }

    // MARK: - Remove

    public func removeNode(id: UUID) {
        let filteredNodes = graph.nodes.filter { $0.id != id }
        let filteredEdges = graph.edges.filter { $0.source != id && $0.target != id }
        graph = SDKGraph(nodes: filteredNodes, edges: filteredEdges)
        persistGraph()
    }

    public func removeEdge(source: UUID, target: UUID) {
        let filteredEdges = graph.edges.filter { !($0.source == source && $0.target == target) }
        graph = SDKGraph(nodes: graph.nodes, edges: filteredEdges)
        persistGraph()
    }

    // MARK: - Build from Workspace

    private func buildGraphFromWorkspace() {
        var nodes: [SDKNode] = graph.nodes

        let tasks = WorkspaceAPI.shared.tasks.listTasks()
        for task in tasks {
            if !nodes.contains(where: { $0.id == task.id }) {
                nodes.append(SDKNode(id: task.id, label: task.title, type: "task"))
            }
        }

        let notes = WorkspaceAPI.shared.notes.listNotes()
        for note in notes {
            if !nodes.contains(where: { $0.id == note.id }) {
                nodes.append(SDKNode(id: note.id, label: note.title, type: "note"))
            }
        }

        let decks = WorkspaceAPI.shared.slides.listDecks()
        for deck in decks {
            if !nodes.contains(where: { $0.id == deck.id }) {
                nodes.append(SDKNode(id: deck.id, label: deck.title, type: "slide"))
            }
        }

        graph = SDKGraph(nodes: nodes, edges: graph.edges)
    }

    // MARK: - Persistence

    private func persistGraph() {
        let graphData = CodableGraph(
            nodes: graph.nodes.map { CodableNode(id: $0.id, label: $0.label, type: $0.type) },
            edges: graph.edges.map { CodableEdge(id: $0.id, source: $0.source, target: $0.target, label: $0.label) }
        )

        queue.async { [weak self] in
            guard let url = self?.persistenceURL else { return }
            if let data = try? JSONEncoder().encode(graphData) {
                try? data.write(to: url)
            }
        }
    }

    private func loadGraph() {
        guard let data = try? Data(contentsOf: persistenceURL),
              let codable = try? JSONDecoder().decode(CodableGraph.self, from: data) else { return }

        graph = SDKGraph(
            nodes: codable.nodes.map { SDKNode(id: $0.id, label: $0.label, type: $0.type) },
            edges: codable.edges.map { SDKEdge(source: $0.source, target: $0.target, label: $0.label) }
        )
    }
}

// MARK: - Codable Graph Types

private struct CodableGraph: Codable {
    let nodes: [CodableNode]
    let edges: [CodableEdge]
}

private struct CodableNode: Codable {
    let id: UUID
    let label: String
    let type: String
}

private struct CodableEdge: Codable {
    let id: UUID
    let source: UUID
    let target: UUID
    let label: String
}
