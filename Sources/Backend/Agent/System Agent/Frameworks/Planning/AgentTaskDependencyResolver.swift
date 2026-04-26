import Foundation

final class AgentTaskDependencyResolver {
    init() {}

    func resolve(graph: AgentTaskGraph) -> [String] {
        var inDegree: [String: Int] = [:]
        let edges = graph.edges

        // Initialize in-degree for all tasks in the graph
        for (task, deps) in edges {
            inDegree[task, default: 0] += 0
            for dep in deps {
                inDegree[dep, default: 0] += 1
            }
        }

        // Use a priority queue (simulated with sorted array) for BFS
        var queue = inDegree.filter { $0.value == 0 }.map(\.key).sorted()
        var result: [String] = []
        var mutableEdges = edges

        while !queue.isEmpty {
            let task = queue.removeFirst()
            result.append(task)

            // Find tasks that depend on the current task
            for (dependent, deps) in mutableEdges where deps.contains(task) {
                mutableEdges[dependent]?.remove(task)
                inDegree[dependent, default: 1] -= 1
                if inDegree[dependent] == 0 {
                    queue.append(dependent)
                    queue.sort()
                }
            }
        }

        return result
    }
}
