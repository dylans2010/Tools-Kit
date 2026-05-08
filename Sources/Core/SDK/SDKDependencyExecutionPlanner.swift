import Foundation

public final class SDKDependencyExecutionPlanner {
    public init() {}

    public func resolveExecutionOrder(for nodes: [SDKDependencyNode]) throws -> [SDKDependencyNode] {
        var idMap = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        var indegree: [UUID: Int] = [:]
        var adjacency: [UUID: [UUID]] = [:]

        for node in nodes {
            indegree[node.id] = indegree[node.id, default: 0]
            for target in node.linkedTo {
                adjacency[target, default: []].append(node.id)
                indegree[node.id, default: 0] += 1
            }
        }

        var queue = indegree.filter { $0.value == 0 }.map(\.key)
        var ordered: [SDKDependencyNode] = []

        while let current = queue.popLast() {
            guard let node = idMap[current] else { continue }
            ordered.append(node)
            for dependent in adjacency[current] ?? [] {
                indegree[dependent, default: 0] -= 1
                if indegree[dependent] == 0 {
                    queue.append(dependent)
                }
            }
            idMap.removeValue(forKey: current)
        }

        if !idMap.isEmpty {
            throw SDKError.validationError(reason: "Circular dependency graph detected")
        }

        return ordered
    }
}
