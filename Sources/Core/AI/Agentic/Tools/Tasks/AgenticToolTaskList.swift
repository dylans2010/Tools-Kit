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
        case "critical": tasks = tasks.filter { $0.priority == .critical }
        case "high": tasks = tasks.filter { $0.priority == .high }
        case "medium": tasks = tasks.filter { $0.priority == .medium }
        case "low": tasks = tasks.filter { $0.priority == .low }
        case "overdue": tasks = tasks.filter { $0.isOverdue }
        case "today": tasks = tasks.filter { $0.isDueToday }
        default: break
        }

        let priorityOrder: [WorkspaceTask.TaskPriority] = [.critical, .high, .medium, .low]
        switch sortBy.lowercased() {
        case "title": tasks.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case "priority": tasks.sort {
            let i0 = priorityOrder.firstIndex(of: $0.priority) ?? priorityOrder.count
            let i1 = priorityOrder.firstIndex(of: $1.priority) ?? priorityOrder.count
            return i0 < i1
        }
        case "duedate": tasks.sort { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        case "created": tasks.sort { $0.createdAt > $1.createdAt }
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
