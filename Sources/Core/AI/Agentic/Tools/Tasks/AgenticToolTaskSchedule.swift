import Foundation

struct AgenticToolTaskSchedule: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "task_schedule",
        description: "Schedule a task for a specific time slot",
        category: "tasks",
        inputSchema: ["taskId": "String", "scheduledDate": "String", "duration": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let taskIdStr = parameters["taskId"] ?? ""
        let scheduledDate = parameters["scheduledDate"] ?? ""
        let duration = parameters["duration"] ?? "30"

        guard let taskId = UUID(uuidString: taskIdStr),
              let task = TasksManager.shared.tasks.first(where: { $0.id == taskId }) else {
            throw AgenticToolExecutionError.executionFailed("task_schedule", NSError(domain: "AgenticTools", code: 1, userInfo: [NSLocalizedDescriptionKey: "Task not found"]))
        }

        let formatter = ISO8601DateFormatter()
        let date = formatter.date(from: scheduledDate) ?? Date()
        let durationMinutes = Int(duration) ?? 30

        let event = CalendarEvent(
            title: "Task: \(task.title)",
            description: task.description,
            date: date,
            startTime: date,
            endTime: date.addingTimeInterval(TimeInterval(durationMinutes * 60))
        )
        CalendarManager.shared.addEvent(event)

        return AgenticToolOutput(
            summary: "Scheduled task '\(task.title)' for \(scheduledDate) (\(durationMinutes) min)",
            generatedCode: nil,
            metadata: ["taskId": taskIdStr, "eventId": event.id.uuidString, "duration": "\(durationMinutes)"],
            dataPayload: ["scheduledDate": scheduledDate, "taskTitle": task.title]
        )
    }
}
