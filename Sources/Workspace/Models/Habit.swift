import Foundation

struct Habit: Identifiable, Codable, Sendable {
    var id: UUID
    var name: String
    var description: String
    var icon: String
    var colorHex: String
    var frequency: HabitFrequency
    var targetCount: Int
    var completionHistory: [String: Int]
    var createdAt: Date

    private enum CodingKeys: String, CodingKey, Sendable {
        case id, name, description, icon, colorHex, frequency, targetCount, completionHistory, createdAt
    }

    init(id: UUID = UUID(),
         name: String,
         description: String = "",
         icon: String = "checkmark.circle",
         colorHex: String = "#007AFF",
         frequency: HabitFrequency = .daily,
         targetCount: Int = 1,
         completionHistory: [String: Int] = [:],
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.colorHex = colorHex
        self.frequency = frequency
        self.targetCount = targetCount
        self.completionHistory = completionHistory
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        icon = try container.decodeIfPresent(String.self, forKey: .icon) ?? "checkmark.circle"
        colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex) ?? "#007AFF"
        frequency = try container.decodeIfPresent(HabitFrequency.self, forKey: .frequency) ?? .daily
        targetCount = try container.decodeIfPresent(Int.self, forKey: .targetCount) ?? 1
        completionHistory = try container.decodeIfPresent([String: Int].self, forKey: .completionHistory) ?? [:]
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    var currentStreak: Int {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var streak = 0
        var checkDate = Date()
        while true {
            let key = formatter.string(from: checkDate)
            let count = completionHistory[key] ?? 0
            if count >= targetCount {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else if formatter.string(from: Date()) == key {
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
                continue
            } else {
                break
            }
            if streak > 365 { break }
        }
        return streak
    }

    var longestStreak: Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let sortedDays = completionHistory.keys.sorted()
        guard !sortedDays.isEmpty else { return 0 }
        var longest = 0
        var current = 0
        var previousDate: Date? = nil
        let calendar = Calendar.current
        for dayStr in sortedDays {
            guard let date = formatter.date(from: dayStr) else { continue }
            let count = completionHistory[dayStr] ?? 0
            guard count >= targetCount else {
                if current > longest { longest = current }
                current = 0
                previousDate = nil
                continue
            }
            if let prev = previousDate, calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: prev) ?? prev) {
                current += 1
            } else {
                if current > longest { longest = current }
                current = 1
            }
            previousDate = date
        }
        if current > longest { longest = current }
        return longest
    }

    func todayCount() -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return completionHistory[formatter.string(from: Date())] ?? 0
    }

    func isCompletedToday() -> Bool {
        todayCount() >= targetCount
    }

    func weeklyCompletionRate() -> Double {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var completed = 0
        for offset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -offset, to: Date()) {
                let key = formatter.string(from: date)
                if (completionHistory[key] ?? 0) >= targetCount { completed += 1 }
            }
        }
        return Double(completed) / 7.0
    }

    func last30DayCounts() -> [(String, Int)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return (0..<30).reversed().compactMap { offset -> (String, Int)? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let key = formatter.string(from: date)
            return (key, completionHistory[key] ?? 0)
        }
    }
}

enum HabitFrequency: String, Codable, CaseIterable, Sendable {
    case daily = "Daily"
    case weekly = "Weekly"
    case custom = "Custom"
}
