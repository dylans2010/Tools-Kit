import Foundation
import FoundationModels

struct AgenticToolCalendarConflictResolver: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "calendar_conflict_resolver",
        description: "Detect and resolve scheduling conflicts",
        category: "calendar",
        inputSchema: ["dateRange": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let dateRange = parameters["dateRange"] ?? "today"

        let manager = CalendarManager.shared
        let events = manager.events.sorted { $0.startTime < $1.startTime }

        var conflicts: [(CalendarEvent, CalendarEvent)] = []
        for i in 0..<events.count {
            for j in (i + 1)..<events.count {
                if events[i].endTime > events[j].startTime {
                    conflicts.append((events[i], events[j]))
                }
            }
        }

        if conflicts.isEmpty {
            return AgenticToolOutput(
                summary: "No scheduling conflicts detected",
                generatedCode: nil,
                metadata: ["dateRange": dateRange, "conflictCount": "0"],
                dataPayload: ["result": "No conflicts found"]
            )
        }

        let conflictDescriptions = conflicts.prefix(10).map {
            "'\($0.0.title)' overlaps with '\($0.1.title)'"
        }.joined(separator: "\n")

        let session = LanguageModelSession(instructions: "You are a scheduling conflict resolver. Suggest resolutions for overlapping events.")
        let response = try await session.respond(to: "Resolve these scheduling conflicts:\n\(conflictDescriptions)")

        var payload: [String: String] = ["conflictCount": "\(conflicts.count)"]
        payload["resolution"] = response.content

        return AgenticToolOutput(
            summary: "Found \(conflicts.count) conflicts, generated resolution suggestions",
            generatedCode: nil,
            metadata: ["dateRange": dateRange, "conflictCount": "\(conflicts.count)"],
            dataPayload: payload
        )
    }
}
