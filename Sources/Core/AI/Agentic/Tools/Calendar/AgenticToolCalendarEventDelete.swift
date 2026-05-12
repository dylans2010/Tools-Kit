import Foundation

struct AgenticToolCalendarEventDelete: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "calendar_event_delete",
        description: "Delete a calendar event",
        category: "calendar",
        inputSchema: ["eventId": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let eventIdStr = parameters["eventId"] ?? ""

        guard let eventId = UUID(uuidString: eventIdStr) else {
            throw AgenticToolExecutionError.executionFailed("calendar_event_delete", NSError(domain: "AgenticTools", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid event ID"]))
        }

        let manager = CalendarManager.shared
        guard let event = manager.events.first(where: { $0.id == eventId }) else {
            throw AgenticToolExecutionError.executionFailed("calendar_event_delete", NSError(domain: "AgenticTools", code: 2, userInfo: [NSLocalizedDescriptionKey: "Event not found"]))
        }

        let title = event.title
        manager.deleteEvent(event)

        return AgenticToolOutput(
            summary: "Deleted calendar event '\(title)' (\(eventIdStr))",
            generatedCode: nil,
            metadata: ["eventId": eventIdStr, "deleted": "true"],
            dataPayload: ["deletedTitle": title]
        )
    }
}
