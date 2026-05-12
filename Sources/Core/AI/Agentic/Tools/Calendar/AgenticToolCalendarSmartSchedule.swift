import Foundation
import FoundationModels

struct AgenticToolCalendarSmartSchedule: AgenticToolProtocol, Sendable {
    let definition = WorkspaceAIToolDefinition(
        name: "calendar_smart_schedule",
        description: "AI-powered smart scheduling based on preferences and patterns",
        category: "calendar",
        inputSchema: ["title": "String", "duration": "String", "priority": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let title = parameters["title"] ?? ""
        let durationStr = parameters["duration"] ?? "30"
        let priority = parameters["priority"] ?? "medium"
        let durationMinutes = Int(durationStr) ?? 30

        let manager = CalendarManager.shared
        let events = manager.events.sorted { $0.startTime < $1.startTime }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let eventList = events.prefix(20).map { "\($0.title): \(formatter.string(from: $0.startTime)) - \(formatter.string(from: $0.endTime))" }.joined(separator: "\n")

        let session = LanguageModelSession(instructions: "You are a smart scheduling AI. Find the optimal time slot for a new event based on existing schedule patterns and priority.")
        let prompt = """
        Schedule a new event: '\(title)'
        Duration: \(durationMinutes) minutes
        Priority: \(priority)
        Current schedule:
        \(eventList)

        Suggest the optimal time slot and explain your reasoning.
        """

        let response = try await session.respond(to: prompt)

        return AgenticToolOutput(
            summary: "Smart-scheduled '\(title)' (\(durationMinutes) min, \(priority) priority)",
            generatedCode: nil,
            metadata: ["title": title, "duration": durationStr, "priority": priority],
            dataPayload: ["recommendation": response.content]
        )
    }
}
