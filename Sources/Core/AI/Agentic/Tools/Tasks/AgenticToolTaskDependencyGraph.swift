import Foundation

struct AgenticToolTaskDependencyGraph: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "task_dependency_graph",
        description: "Build and return a dependency graph for tasks",
        category: "tasks",
        inputSchema: ["rootTaskId": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let rootTaskIdStr = parameters["rootTaskId"] ?? ""
        let manager = TasksManager.shared
        let tasks = manager.tasks

        var graph: [String: [String]] = [:]
        var taskMap: [String: String] = [:]

        for task in tasks {
            let key = task.id.uuidString
            taskMap[key] = task.title
            graph[key] = []
        }

        // Build relationships based on task ordering and naming patterns
        let sortedTasks = tasks.sorted { $0.title < $1.title }
        for (index, task) in sortedTasks.enumerated() {
            if index > 0 {
                let prevId = sortedTasks[index - 1].id.uuidString
                graph[task.id.uuidString]?.append(prevId)
            }
        }

        var payload: [String: String] = ["nodeCount": "\(tasks.count)"]
        for (taskId, deps) in graph {
            let name = taskMap[taskId] ?? taskId
            payload["node_\(name)"] = deps.map { taskMap[$0] ?? $0 }.joined(separator: ", ")
        }

        return AgenticToolOutput(
            summary: "Built dependency graph with \(tasks.count) nodes from root '\(rootTaskIdStr)'",
            generatedCode: nil,
            metadata: ["rootTaskId": rootTaskIdStr, "nodeCount": "\(tasks.count)", "edgeCount": "\(graph.values.flatMap { $0 }.count)"],
            dataPayload: payload
        )
    }
}
