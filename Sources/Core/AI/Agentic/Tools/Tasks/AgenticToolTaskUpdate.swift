import Foundation

struct AgenticToolTaskUpdate: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "task_update",
        description: "Update an existing task by ID",
        category: "tasks",
        inputSchema: ["taskId": "String", "field": "String", "value": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let taskIdStr = parameters["taskId"] ?? ""
        let field = parameters["field"] ?? ""
        let value = parameters["value"] ?? ""

        guard let taskId = UUID(uuidString: taskIdStr) else {
            throw AgenticToolExecutionError.executionFailed("task_update", NSError(domain: "AgenticTools", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid task ID"]))
        }

        let manager = TasksManager.shared
        guard var task = manager.tasks.first(where: { $0.id == taskId }) else {
            throw AgenticToolExecutionError.executionFailed("task_update", NSError(domain: "AgenticTools", code: 2, userInfo: [NSLocalizedDescriptionKey: "Task not found"]))
        }

        switch field.lowercased() {
        case "title": task.title = value
        case "description": task.description = value
        case "completed": task.completed = (value.lowercased() == "true")
        case "priority":
            switch value.lowercased() {
            case "high": task.priority = .high
            case "low": task.priority = .low
            case "critical": task.priority = .critical
            default: task.priority = .medium
            }
        case "duedate":
            if value.isEmpty {
                task.dueDate = nil
            } else {
                let formatter = ISO8601DateFormatter()
                task.dueDate = formatter.date(from: value)
            }
        default: break
        }

        manager.updateTask(task)

        return AgenticToolOutput(
            summary: "Updated task \(taskIdStr): set \(field) to '\(value)'",
            generatedCode: nil,
            metadata: ["taskId": taskIdStr, "field": field],
            dataPayload: ["updatedValue": value]
        )
    }
}
