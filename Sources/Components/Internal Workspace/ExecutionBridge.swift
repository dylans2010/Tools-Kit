import Foundation
import os.log

final class ExecutionBridge {
    static let shared = ExecutionBridge()

    private let calendarManager = CalendarManager.shared
    private let tasksManager = TasksManager.shared
    private let mailAIService = MailAIService.shared

    struct TimeExtraction: Codable {
        let startISO8601: String
        let endISO8601: String
    }

    private init() {}

    func convertThreadToCalendarEvent(thread: MailThread) async throws -> CalendarEvent {
        let summary = try await mailAIService.summarizeThread(thread)

        let schema = """
        {
          "type": "object",
          "required": ["startISO8601", "endISO8601"],
          "properties": {
            "startISO8601": { "type": "string" },
            "endISO8601": { "type": "string" }
          }
        }
        """
        let prompt = "Extract start and end times for a meeting from this summary: \(summary). Use ISO8601 format."
        let json = try await AIService.shared.generateStructuredJSON(prompt: prompt, jsonSchema: schema)
        let times = try JSONDecoder().decode(TimeExtraction.self, from: json.data(using: .utf8)!)

        let isoFormatter = ISO8601DateFormatter()
        let start = isoFormatter.date(from: times.startISO8601) ?? Date().addingTimeInterval(3600)
        let end = isoFormatter.date(from: times.endISO8601) ?? start.addingTimeInterval(3600)

        let event = CalendarEvent(
            title: "Follow-up: \(thread.subject)",
            description: summary,
            date: start,
            startTime: start,
            endTime: end,
            location: "Virtual Room"
        )

        await MainActor.run {
            calendarManager.addEvent(event)
        }

        return event
    }

    func createTask(title: String, description: String) async throws -> WorkspaceTask {
        let task = WorkspaceTask(
            id: UUID(),
            title: title,
            description: description,
            priority: .medium,
            completed: false,
            createdAt: Date()
        )

        await MainActor.run {
            tasksManager.addTask(task)
        }

        return task
    }
}

struct WorkspaceLogger {
    static let general = Logger(subsystem: "com.workspace", category: "General")
    static let db = Logger(subsystem: "com.workspace", category: "Database")
    static let ai = Logger(subsystem: "com.workspace", category: "AI")
    static let render = Logger(subsystem: "com.workspace", category: "Render")
}
