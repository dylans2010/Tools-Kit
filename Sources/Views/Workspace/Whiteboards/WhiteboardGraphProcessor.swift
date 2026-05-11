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
            let connected: Set<UUID>
            if node.type == .group {
                connected = dfs(start: node.id, adjacency: adjacency, initialVisited: visited)
                visited.formUnion(connected)
            } else {
                connected = bfs(start: node.id, adjacency: adjacency, visited: &visited)
            }
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
            let topic = extractTopic(from: cluster)
            let summary = cluster.nodes.map { $0.content }.prefix(4).joined(separator: " • ")
            return WhiteboardSlideSection(
                title: topic,
                summary: summary,
                nodeIDs: cluster.nodes.map(\.id)
            )
        }
    }

    private func extractTopic(from cluster: WhiteboardGraphCluster) -> String {
        let titleTokens = cluster.nodes
            .map(\.title)
            .flatMap { $0.split(separator: " ") }
            .map(String.init)
            .filter { $0.count > 2 }

        guard !titleTokens.isEmpty else { return "Topic" }
        let frequencies = Dictionary(grouping: titleTokens.map { $0.lowercased() }, by: { $0 }).mapValues(\.count)
        let ranked = frequencies.sorted { $0.value > $1.value }.prefix(3).map(\.key)
        return ranked.map { $0.capitalized }.joined(separator: " ")
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

    private func dfs(start: UUID, adjacency: [UUID: Set<UUID>], initialVisited: Set<UUID>) -> Set<UUID> {
        var stack = [start]
        var visited: Set<UUID> = initialVisited

        while let current = stack.popLast() {
            if visited.contains(current) { continue }
            visited.insert(current)
            for neighbor in adjacency[current] ?? [] {
                if !visited.contains(neighbor) {
                    stack.append(neighbor)
                }
            }
        }

        return visited
    }

    private func densityScore(nodeCount: Int, edgeCount: Int) -> Double {
        guard nodeCount > 1 else { return Double(nodeCount) }
        let maxEdges = Double(nodeCount * (nodeCount - 1) / 2)
        return (Double(edgeCount) / maxEdges) * 10
    }
}
