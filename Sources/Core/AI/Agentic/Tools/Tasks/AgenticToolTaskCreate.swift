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

        let priority: TaskPriority
        switch priorityRaw.lowercased() {
        case "high": priority = .high
        case "low": priority = .low
        default: priority = .medium
        }

        let task = TaskItem(title: title, description: description, priority: priority)
        TasksManager.shared.addTask(task)

        return AgenticToolOutput(
            summary: "Created task '\(title)' with \(priorityRaw) priority",
            generatedCode: nil,
            metadata: ["taskId": task.id.uuidString, "priority": priorityRaw, "dueDate": dueDateStr],
            dataPayload: ["title": title, "description": description]
        )
    }
}
