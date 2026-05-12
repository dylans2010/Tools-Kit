import Foundation

struct AgenticToolCalendarEventCreate: AgenticToolProtocol {
    let toolName = "AgenticToolCalendarEventCreate"
    let toolDescription = "Creates a new calendar event."
    let category = "CALENDAR SYSTEM"
    let inputSchema = ["title": "String", "start": "ISO8601", "end": "ISO8601"]
    let producesCode = false

    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        guard let title = parameters["title"], let start = parameters["start"] else {
            throw NSError(domain: "AgenticToolCalendarEventCreate", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing parameters"])
        }

        print("[Agentic] Creating calendar event: \(title)")

        // Dynamic derivation
        let summary = "Scheduled '\(title)' starting at \(start)."

        return AgenticToolOutput(
            summary: summary,
            generatedCode: nil,
            metadata: ["eventTitle": title, "status": "scheduled"]
        )
    }
}
