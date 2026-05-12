import Foundation

struct AgenticToolTaskList: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "task_list",
        description: "List all tasks with optional filters",
        category: "tasks",
        inputSchema: ["filter": "String", "sortBy": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let filter = parameters["filter"] ?? "all"
        let sortBy = parameters["sortBy"] ?? "priority"

        let manager = TasksManager.shared
        var tasks = manager.tasks

        switch filter.lowercased() {
        case "completed": tasks = tasks.filter { $0.completed }
        case "pending": tasks = tasks.filter { !$0.completed }
        case "high": tasks = tasks.filter { $0.priority == .high }
        case "medium": tasks = tasks.filter { $0.priority == .medium }
        case "low": tasks = tasks.filter { $0.priority == .low }
        default: break
        }

        switch sortBy.lowercased() {
        case "title": tasks.sort { $0.title < $1.title }
        case "priority": tasks.sort { $0.priority.rawValue > $1.priority.rawValue }
        default: break
        }

        var payload: [String: String] = ["count": "\(tasks.count)"]
        for (index, task) in tasks.prefix(50).enumerated() {
            payload["task_\(index)"] = "\(task.title) [\(task.priority.rawValue)] \(task.completed ? "✓" : "○")"
        }

        return AgenticToolOutput(
            summary: "Found \(tasks.count) tasks (filter: \(filter), sort: \(sortBy))",
            generatedCode: nil,
            metadata: ["filter": filter, "sortBy": sortBy, "totalCount": "\(tasks.count)"],
            dataPayload: payload
        )
    }
}
