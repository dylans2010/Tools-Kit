import Foundation

struct AgentTaskPlanner: Sendable {
    func orderedTasks(from graph: AgentTaskGraph) -> [String] {
        var inDegree: [String: Int] = [:]
        for (task, deps) in graph.edges {
            inDegree[task, default: 0] += 0
            for dep in deps { inDegree[dep, default: 0] += 1 }
        }
        var queue = inDegree.filter { $0.value == 0 }.map(\.key).sorted()
        var result: [String] = []
        var mutable = graph.edges
        while let task = queue.first {
            queue.removeFirst()
            result.append(task)
            for dependent in mutable.keys where mutable[dependent]?.contains(task) == true {
                mutable[dependent]?.remove(task)
                if mutable[dependent]?.isEmpty == true { queue.append(dependent); queue.sort() }
            }
        }
        return result
    }
}
