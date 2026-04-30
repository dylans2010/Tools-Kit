import Foundation

/// Coordinates actions across different modules, such as converting an email into a calendar event.
final class ExecutionBridge {
    static let shared = ExecutionBridge()

    private let calendarManager = CalendarManager.shared
    private let mailAIService = MailAIService.shared

    struct TimeExtraction: Codable {
        let startISO8601: String
        let endISO8601: String
    }

    private init() {}

    /// Converts a mail thread into a calendar event.
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
}
