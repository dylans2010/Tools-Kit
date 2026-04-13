import Foundation
import SwiftUI

final class CalendarManager: ObservableObject {
    static let shared = CalendarManager()

    @Published var events: [CalendarEvent] = []

    private let storageURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Workspace/Calendar", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("events.json")
    }()

    private init() {
        load()
    }

    // MARK: - CRUD

    func addEvent(_ event: CalendarEvent) {
        events.append(event)
        save()
    }

    func updateEvent(_ event: CalendarEvent) {
        if let idx = events.firstIndex(where: { $0.id == event.id }) {
            events[idx] = event
            save()
        }
    }

    func deleteEvent(_ event: CalendarEvent) {
        events.removeAll { $0.id == event.id }
        save()
    }

    // MARK: - Queries

    func events(on date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        return events.filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.startTime < $1.startTime }
    }

    func events(in month: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: month)
        return events.filter {
            let ec = calendar.dateComponents([.year, .month], from: $0.date)
            return ec.year == comps.year && ec.month == comps.month
        }
    }

    func events(in week: Date) -> [CalendarEvent] {
        guard let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: week) else { return [] }
        return events.filter { weekInterval.contains($0.date) }.sorted { $0.startTime < $1.startTime }
    }

    var upcomingEvents: [CalendarEvent] {
        events.filter { $0.date >= Calendar.current.startOfDay(for: Date()) }
            .sorted { $0.startTime < $1.startTime }
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([CalendarEvent].self, from: data) else { return }
        events = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(events) else { return }
        try? data.write(to: storageURL)
    }
}
