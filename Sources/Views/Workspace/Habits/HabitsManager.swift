import Foundation
import SwiftUI

final class HabitsManager: ObservableObject {
    static let shared = HabitsManager()

    @Published var habits: [Habit] = []

    private let storageURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Workspace/Habits", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("habits.json")
    }()

    private init() {
        load()
    }

    // MARK: - CRUD

    func addHabit(_ habit: Habit) {
        habits.append(habit)
        save()
    }

    func updateHabit(_ habit: Habit) {
        if let idx = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[idx] = habit
            save()
        }
    }

    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        save()
    }

    func increment(_ habit: Habit) {
        guard let idx = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let key = dateKey(for: Date())
        habits[idx].completionHistory[key, default: 0] += 1
        save()
    }

    func decrement(_ habit: Habit) {
        guard let idx = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let key = dateKey(for: Date())
        let current = habits[idx].completionHistory[key, default: 0]
        if current > 0 {
            habits[idx].completionHistory[key] = current - 1
            save()
        }
    }

    func resetToday(_ habit: Habit) {
        guard let idx = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[idx].completionHistory[dateKey(for: Date())] = 0
        save()
    }

    // MARK: - Helpers

    func dateKey(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    var todayHabits: [Habit] { habits }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([Habit].self, from: data) else { return }
        habits = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(habits) else { return }
        try? data.write(to: storageURL)
    }
}
