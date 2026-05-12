import Foundation

struct AgenticToolTaskCreate: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "task_create",
        description: "Create a new task with title, description, priority, and due date",
        category: "tasks",
        inputSchema: ["title": "String", "description": "String", "priority": "String", "dueDate": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let title = parameters["title"] ?? ""
        let description = parameters["description"] ?? ""
        let priorityRaw = parameters["priority"] ?? "medium"
        let dueDateStr = parameters["dueDate"] ?? ""

        let priority: WorkspaceTask.TaskPriority
        switch priorityRaw.lowercased() {
        case "high": priority = .high
        case "low": priority = .low
        case "critical": priority = .critical
        default: priority = .medium
        }

        var dueDate: Date? = nil
        if !dueDateStr.isEmpty {
            let formatter = ISO8601DateFormatter()
            dueDate = formatter.date(from: dueDateStr)
        }

        let task = WorkspaceTask(
            title: title,
            description: description,
            dueDate: dueDate,
            priority: priority
        )
        TasksManager.shared.addTask(task)

        return AgenticToolOutput(
            summary: "Created task '\(title)' with \(priorityRaw) priority",
            generatedCode: nil,
            metadata: ["taskId": task.id.uuidString, "priority": priorityRaw, "dueDate": dueDateStr],
            dataPayload: ["title": title, "description": description]
        )
    }
}
