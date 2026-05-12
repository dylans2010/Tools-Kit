import Foundation

struct AgenticToolCalendarEventUpdate: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "calendar_event_update",
        description: "Update an existing calendar event",
        category: "calendar",
        inputSchema: ["eventId": "String", "field": "String", "value": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let eventIdStr = parameters["eventId"] ?? ""
        let field = parameters["field"] ?? ""
        let value = parameters["value"] ?? ""

        guard let eventId = UUID(uuidString: eventIdStr) else {
            throw AgenticToolExecutionError.executionFailed("calendar_event_update", NSError(domain: "AgenticTools", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid event ID"]))
        }

        let manager = CalendarManager.shared
        guard var event = manager.events.first(where: { $0.id == eventId }) else {
            throw AgenticToolExecutionError.executionFailed("calendar_event_update", NSError(domain: "AgenticTools", code: 2, userInfo: [NSLocalizedDescriptionKey: "Event not found"]))
        }

        let formatter = ISO8601DateFormatter()

        switch field.lowercased() {
        case "title": event.title = value
        case "description": event.description = value
        case "location": event.location = value
        case "starttime":
            if let date = formatter.date(from: value) {
                event.startTime = date
                event.date = date
            }
        case "endtime":
            if let date = formatter.date(from: value) { event.endTime = date }
        case "priority":
            switch value.lowercased() {
            case "low": event.priority = .low
            case "high": event.priority = .high
            case "critical": event.priority = .critical
            default: event.priority = .normal
            }
        default: break
        }

        manager.updateEvent(event)

        return AgenticToolOutput(
            summary: "Updated event \(eventIdStr): set \(field) to '\(value)'",
            generatedCode: nil,
            metadata: ["eventId": eventIdStr, "field": field],
            dataPayload: ["updatedValue": value]
        )
    }
}
