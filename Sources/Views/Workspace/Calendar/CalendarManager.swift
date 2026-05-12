import Foundation
import Combine

@MainActor
final class CalendarManager: ObservableObject {
    nonisolated(unsafe) static let shared = CalendarManager()

    @Published var events: [CalendarEvent] = []
    private let aiService = AIService.shared
    private let aiDecoder = AIResponseDecoder()

    private var saveDir: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Workspace/Calendar", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var eventsURL: URL { saveDir.appendingPathComponent("events.json") }

    private let calendar = Calendar.current

    private init() { load() }

    // MARK: - CRUD

    func addEvent(_ event: CalendarEvent) {
        events.append(event)
        events.sort { $0.startTime < $1.startTime }
        save()
    }

    func updateEvent(_ event: CalendarEvent) {
        if let idx = events.firstIndex(where: { $0.id == event.id }) {
            events[idx] = event
            events.sort { $0.startTime < $1.startTime }
            save()
        }
    }

    func deleteEvent(_ event: CalendarEvent) {
        events.removeAll { $0.id == event.id }
        save()
    }

    // MARK: - Queries

    func events(on date: Date) -> [CalendarEvent] {
        events.filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.startTime < $1.startTime }
    }

    func events(in week: Date) -> [CalendarEvent] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: week) else { return [] }
        return events.filter { weekInterval.contains($0.date) }
            .sorted { $0.startTime < $1.startTime }
    }

    func upcomingEvents(limit: Int = 20) -> [CalendarEvent] {
        let now = Date()
        return events.filter { $0.startTime >= now }
            .sorted { $0.startTime < $1.startTime }
            .prefix(limit)
            .map { $0 }
    }

    func hasEvents(on date: Date) -> Bool {
        events.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }

    // MARK: - Intelligence

    func conflictProbability(for date: Date) -> Double {
        let dayEvents = events(on: date)
        if dayEvents.count > 5 { return 0.9 }
        if dayEvents.count > 3 { return 0.5 }
        return 0.1
    }

    func suggestOptimalTime(for title: String, duration: TimeInterval) async -> Date? {
        return Date().addingTimeInterval(3600 * 4)
    }

    func generateMeetingAgenda(for event: CalendarEvent) async throws -> String {
        let prompt = "Generate a professional meeting agenda for: \(event.title). Description: \(event.description)"
        return try await aiService.processText(prompt: prompt, systemPrompt: "Return a structured markdown agenda.")
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: eventsURL),
              let decoded = try? JSONDecoder().decode([CalendarEvent].self, from: data) else { return }
        events = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(events) else { return }
        try? data.write(to: eventsURL, options: .atomic)
    }

    // MARK: - AI Scheduling

    struct AICalendarEventDraft: Codable, Sendable {
        let title: String
        let details: String
        let startISO8601: String
        let endISO8601: String
        let location: String
    }

    struct AICalendarInsights: Codable, Sendable {
        let parsedEvents: [AICalendarEventDraft]
        let autoScheduledTasks: [String]
        let conflicts: [String]
        let optimalScheduling: [String]
    }

    private var aiSchemaString: String {
        """
        {
          "type": "object",
          "required": ["parsedEvents", "autoScheduledTasks", "conflicts", "optimalScheduling"],
          "properties": {
            "parsedEvents": {
              "type": "array",
              "items": {
                "type": "object",
                "required": ["title", "details", "startISO8601", "endISO8601", "location"],
                "properties": {
                  "title": { "type": "string" },
                  "details": { "type": "string" },
                  "startISO8601": { "type": "string" },
                  "endISO8601": { "type": "string" },
                  "location": { "type": "string" }
                }
              }
            },
            "autoScheduledTasks": { "type": "array", "items": { "type": "string" } },
            "conflicts": { "type": "array", "items": { "type": "string" } },
            "optimalScheduling": { "type": "array", "items": { "type": "string" } }
          }
        }
        """
    }

    private var aiSchema: AIJSONType {
        .object([
            "parsedEvents": .array(.object([
                "title": .string,
                "details": .string,
                "startISO8601": .string,
                "endISO8601": .string,
                "location": .string
            ])),
            "autoScheduledTasks": .array(.string),
            "conflicts": .array(.string),
            "optimalScheduling": .array(.string)
        ])
    }

    func generateSchedulingInsights(from prompt: String) async throws -> AICalendarInsights {
        let existing = upcomingEvents(limit: 20).map {
            "\($0.title) | \($0.formattedDate) | \($0.formattedTimeRange)"
        }.joined(separator: "\n")
        let request = """
        User scheduling request (may be informal natural language):
        \(prompt)

        Existing events:
        \(existing)
        """
        let json = try await aiService.generateStructuredJSON(
            prompt: request,
            jsonSchema: aiSchemaString,
            preferredModel: "openrouter/free",
            systemPrompt: "You are a scheduling assistant that handles natural language and infers missing time details when possible. Return strict JSON only."
        )
        return try aiDecoder.decode(AICalendarInsights.self, from: json, schema: aiSchema)
    }
}
