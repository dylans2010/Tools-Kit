import Foundation

struct WhiteboardGraphCluster: Identifiable, Codable {
    var id: UUID = UUID()
    var nodes: [WhiteboardNode]
    var edges: [WhiteboardEdge]
    var densityScore: Double
    var importanceScore: Double

    var rankScore: Double { densityScore + importanceScore }
}

struct WhiteboardGraphProcessor {
    func cluster(board: WhiteboardBoard) -> [WhiteboardGraphCluster] {
        let adjacency = adjacencyMap(edges: board.edges)
        var visited = Set<UUID>()
        var clusters: [WhiteboardGraphCluster] = []

        for node in board.nodes {
            guard !visited.contains(node.id) else { continue }
            let connected = bfs(start: node.id, adjacency: adjacency, visited: &visited)
            let clusterNodes = board.nodes.filter { connected.contains($0.id) }
            let clusterEdges = board.edges.filter { connected.contains($0.fromNodeID) && connected.contains($0.toNodeID) }
            let density = densityScore(nodeCount: clusterNodes.count, edgeCount: clusterEdges.count)
            let importance = clusterNodes.reduce(0) { $0 + $1.type.importanceWeight }
            clusters.append(
                WhiteboardGraphCluster(
                    nodes: clusterNodes,
                    edges: clusterEdges,
                    densityScore: density,
                    importanceScore: importance
                )
            )
        }

        return clusters.sorted { $0.rankScore > $1.rankScore }
    }

    func buildSections(from board: WhiteboardBoard) -> [WhiteboardSlideSection] {
        cluster(board: board).map { cluster in
            let titles = cluster.nodes.map(\.title).prefix(3).joined(separator: ", ")
            let summary = cluster.nodes.map { $0.content }.prefix(4).joined(separator: " • ")
            return WhiteboardSlideSection(
                title: titles.isEmpty ? "Topic" : titles,
                summary: summary,
                nodeIDs: cluster.nodes.map(\.id)
            )
        }
    }

    private func adjacencyMap(edges: [WhiteboardEdge]) -> [UUID: Set<UUID>] {
        var map: [UUID: Set<UUID>] = [:]
        for edge in edges {
            map[edge.fromNodeID, default: []].insert(edge.toNodeID)
            map[edge.toNodeID, default: []].insert(edge.fromNodeID)
        }
        return map
    }

    private func bfs(start: UUID, adjacency: [UUID: Set<UUID>], visited: inout Set<UUID>) -> Set<UUID> {
        var queue = [start]
        var group: Set<UUID> = [start]
        visited.insert(start)

        while !queue.isEmpty {
            let current = queue.removeFirst()
            for next in adjacency[current] ?? [] where !visited.contains(next) {
                visited.insert(next)
                group.insert(next)
                queue.append(next)
            }
        }

        return group
    }

    private func densityScore(nodeCount: Int, edgeCount: Int) -> Double {
        guard nodeCount > 1 else { return Double(nodeCount) }
        let maxEdges = Double(nodeCount * (nodeCount - 1) / 2)
        return (Double(edgeCount) / maxEdges) * 10
    }
}
