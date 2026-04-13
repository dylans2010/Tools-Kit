import Foundation
import Combine

final class CalendarManager: ObservableObject {
    static let shared = CalendarManager()

    @Published var events: [CalendarEvent] = []

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

    func events(inMonth date: Date) -> [CalendarEvent] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return [] }
        return events.filter { monthInterval.contains($0.date) }
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
}
