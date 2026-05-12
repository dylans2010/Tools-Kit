import Foundation

struct AgenticToolTaskDelete: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "task_delete",
        description: "Delete a task by ID",
        category: "tasks",
        inputSchema: ["taskId": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let taskIdStr = parameters["taskId"] ?? ""

        guard let taskId = UUID(uuidString: taskIdStr) else {
            throw AgenticToolExecutionError.executionFailed("task_delete", NSError(domain: "AgenticTools", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid task ID"]))
        }

        let manager = TasksManager.shared
        guard let task = manager.tasks.first(where: { $0.id == taskId }) else {
            throw AgenticToolExecutionError.executionFailed("task_delete", NSError(domain: "AgenticTools", code: 2, userInfo: [NSLocalizedDescriptionKey: "Task not found"]))
        }

        let title = task.title
        manager.deleteTask(task)

        return AgenticToolOutput(
            summary: "Deleted task '\(title)' (\(taskIdStr))",
            generatedCode: nil,
            metadata: ["taskId": taskIdStr, "deleted": "true"],
            dataPayload: ["deletedTitle": title]
        )
    }
}
