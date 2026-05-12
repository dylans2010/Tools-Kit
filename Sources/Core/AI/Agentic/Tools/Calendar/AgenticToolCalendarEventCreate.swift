import Foundation

struct AgenticToolCalendarEventCreate: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "calendar_event_create",
        description: "Create a new calendar event",
        category: "calendar",
        inputSchema: ["title": "String", "startDate": "String", "endDate": "String", "description": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let title = parameters["title"] ?? "Untitled Event"
        let startDateStr = parameters["startDate"] ?? ""
        let endDateStr = parameters["endDate"] ?? ""
        let description = parameters["description"] ?? ""

        let formatter = ISO8601DateFormatter()
        let startDate = formatter.date(from: startDateStr) ?? Date()
        let endDate = formatter.date(from: endDateStr) ?? startDate.addingTimeInterval(3600)

        let event = CalendarEvent(
            title: title,
            date: startDate,
            startTime: startDate,
            endTime: endDate,
            description: description
        )
        CalendarManager.shared.addEvent(event)

        return AgenticToolOutput(
            summary: "Created calendar event '\(title)'",
            generatedCode: nil,
            metadata: ["eventId": event.id.uuidString, "start": startDateStr, "end": endDateStr],
            dataPayload: ["title": title, "description": description]
        )
    }
}
