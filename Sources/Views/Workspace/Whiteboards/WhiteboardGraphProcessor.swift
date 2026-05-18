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
        let nodes = board.nodes
        let edges = board.edges
        let adjacency = adjacencyMap(edges: edges)
        var visited = Set<UUID>()
        var clusters: [WhiteboardGraphCluster] = []

        for node in nodes {
            guard !visited.contains(node.id) else { continue }
            let connected: Set<UUID>
            if node.type == .group {
                connected = dfs(start: node.id, adjacency: adjacency, initialVisited: visited)
                visited.formUnion(connected)
            } else {
                connected = bfs(start: node.id, adjacency: adjacency, visited: &visited)
            }

            var clusterNodes: [WhiteboardNode] = []
            for n in nodes {
                if connected.contains(n.id) {
                    clusterNodes.append(n)
                }
            }

            var clusterEdges: [WhiteboardEdge] = []
            for e in edges {
                if connected.contains(e.fromNodeID) && connected.contains(e.toNodeID) {
                    clusterEdges.append(e)
                }
            }

            let density = densityScore(nodeCount: clusterNodes.count, edgeCount: clusterEdges.count)

            var importance = 0.0
            for n in clusterNodes {
                importance += n.type.importanceWeight
            }

            clusters.append(
                WhiteboardGraphCluster(
                    nodes: clusterNodes,
                    edges: clusterEdges,
                    densityScore: density,
                    importanceScore: importance
                )
            )
        }

        var sortedClusters = clusters
        for i in 0..<sortedClusters.count {
            for j in i+1..<sortedClusters.count {
                if sortedClusters[i].rankScore < sortedClusters[j].rankScore {
                    sortedClusters.swapAt(i, j)
                }
            }
        }
        return sortedClusters
    }

    func buildSections(from board: WhiteboardBoard) -> [WhiteboardSlideSection] {
        let clusters = cluster(board: board)
        var sections: [WhiteboardSlideSection] = []

        for cluster in clusters {
            let clusterNodes = cluster.nodes
            let topic = extractTopic(from: cluster)

            var contents: [String] = []
            for n in clusterNodes {
                contents.append(n.content)
            }
            let summary = contents.prefix(4).joined(separator: " • ")

            var nodeIDs: [UUID] = []
            for n in clusterNodes {
                nodeIDs.append(n.id)
            }

            sections.append(
                WhiteboardSlideSection(
                    title: topic,
                    summary: summary,
                    nodeIDs: nodeIDs
                )
            )
        }
        return sections
    }

    private func extractTopic(from cluster: WhiteboardGraphCluster) -> String {
        let nodes = cluster.nodes
        var titleTokens: [String] = []
        for n in nodes {
            let words = n.title.split(separator: " ")
            for word in words {
                let token = String(word)
                if token.count > 2 {
                    titleTokens.append(token)
                }
            }
        }

        guard !titleTokens.isEmpty else { return "Topic" }

        var frequencies: [String: Int] = [:]
        for token in titleTokens {
            let lower = token.lowercased()
            frequencies[lower, default: 0] += 1
        }

        var freqList: [(key: String, value: Int)] = []
        for (key, value) in frequencies {
            freqList.append((key, value))
        }

        for i in 0..<freqList.count {
            for j in i+1..<freqList.count {
                if freqList[i].value < freqList[j].value {
                    freqList.swapAt(i, j)
                }
            }
        }

        let ranked = freqList.prefix(3)
        var capitalizedRanked: [String] = []
        for item in ranked {
            capitalizedRanked.append(item.key.capitalized)
        }

        return capitalizedRanked.joined(separator: " ")
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
