import Foundation

struct HabitItem: Identifiable, Codable, Sendable {
    let id: UUID
    var name: String
    var targetPerWeek: Int
    var completionsByDay: [String: Int]
    var color: String = "blue"

    init(id: UUID = UUID(), name: String, targetPerWeek: Int = 5, completionsByDay: [String: Int] = [:], color: String = "blue") {
        self.id = id
        self.name = name
        self.targetPerWeek = targetPerWeek
        self.completionsByDay = completionsByDay
        self.color = color
    }

    var completedThisWeek: Int {
        // This is a simplification; in a real app, you'd filter by actual week dates
        completionsByDay.values.reduce(0, +)
    }

    var currentStreak: Int {
        let sortedKeys = completionsByDay.keys.sorted().reversed()
        var streak = 0
        let calendar = Calendar.current
        var checkDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for _ in 0..<completionsByDay.count {
            let key = formatter.string(from: checkDate)
            if (completionsByDay[key] ?? 0) > 0 {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                // If it's today and not yet completed, don't break streak yet
                if formatter.string(from: Date()) == key {
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                    continue
                }
                break
            }
        }
        return streak
    }
}

final class HabitTrackerBackend: ObservableObject {
    @Published var habits: [HabitItem] = []
    @Published var newHabitName = ""
    @Published var targetPerWeek = 5

    private let key = "habit_tracker_data_v2"
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    init() {
        load()
        if habits.isEmpty {
            habits = [HabitItem(name: "Drink Water", targetPerWeek: 7), HabitItem(name: "Exercise", targetPerWeek: 4)]
            save()
        }
    }

    func addHabit() {
        let trimmed = newHabitName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        habits.append(HabitItem(name: trimmed, targetPerWeek: targetPerWeek))
        newHabitName = ""
        targetPerWeek = 5
        save()
    }

    func incrementToday(for habitID: UUID) {
        guard let index = habits.firstIndex(where: { $0.id == habitID }) else { return }
        let key = todayKey()
        habits[index].completionsByDay[key, default: 0] += 1
        save()
    }

    func resetToday(for habitID: UUID) {
        guard let index = habits.firstIndex(where: { $0.id == habitID }) else { return }
        habits[index].completionsByDay[todayKey()] = 0
        save()
    }

    func deleteHabit(at offsets: IndexSet) {
        habits.remove(atOffsets: offsets)
        save()
    }

    func todayCount(for habit: HabitItem) -> Int {
        habit.completionsByDay[todayKey(), default: 0]
    }

    private func todayKey() -> String {
        dateFormatter.string(from: Date())
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([HabitItem].self, from: data) else { return }
        habits = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(habits) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
