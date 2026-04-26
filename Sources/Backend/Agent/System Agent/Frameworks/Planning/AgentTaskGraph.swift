import Foundation

struct AgentTaskGraph {
    private(set) var edges: [String: Set<String>] = [:]

    mutating func add(task: String, dependsOn: [String] = []) {
        edges[task, default: []].formUnion(dependsOn)
        for dep in dependsOn where edges[dep] == nil { edges[dep] = [] }
    }

    func dependencies(of task: String) -> [String] {
        Array(edges[task] ?? []).sorted()
    }
}
