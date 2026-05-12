import Foundation

struct AgenticToolCalendarAvailabilityFinder: AgenticToolProtocol {
    let definition = WorkspaceAIToolDefinition(
        name: "calendar_availability_finder",
        description: "Find available time slots",
        category: "calendar",
        inputSchema: ["dateRange": "String", "duration": "String"]
    )

    @MainActor
    func execute(parameters: [String: String]) async throws -> AgenticToolOutput {
        let dateRange = parameters["dateRange"] ?? "today"
        let durationStr = parameters["duration"] ?? "30"
        let durationMinutes = Int(durationStr) ?? 30

        let manager = CalendarManager.shared
        let events = manager.events.sorted { $0.startTime < $1.startTime }

        let calendar = Foundation.Calendar.current
        let now = Date()
        let dayStart = calendar.startOfDay(for: now)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? now

        let todayEvents = events.filter { $0.startTime >= dayStart && $0.startTime < dayEnd }

        var availableSlots: [(Date, Date)] = []
        var cursor = max(dayStart.addingTimeInterval(8 * 3600), now)
        let endOfWork = dayStart.addingTimeInterval(18 * 3600)

        for event in todayEvents {
            if cursor.addingTimeInterval(TimeInterval(durationMinutes * 60)) <= event.startTime {
                availableSlots.append((cursor, event.startTime))
            }
            cursor = max(cursor, event.endTime)
        }

        if cursor.addingTimeInterval(TimeInterval(durationMinutes * 60)) <= endOfWork {
            availableSlots.append((cursor, endOfWork))
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        var payload: [String: String] = ["slotCount": "\(availableSlots.count)"]
        for (index, slot) in availableSlots.prefix(10).enumerated() {
            payload["slot_\(index)"] = "\(formatter.string(from: slot.0)) - \(formatter.string(from: slot.1))"
        }

        return AgenticToolOutput(
            summary: "Found \(availableSlots.count) available slots for \(durationMinutes)-min meetings",
            generatedCode: nil,
            metadata: ["dateRange": dateRange, "duration": durationStr, "eventCount": "\(todayEvents.count)"],
            dataPayload: payload
        )
    }
}
