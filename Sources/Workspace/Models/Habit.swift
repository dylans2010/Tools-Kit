import Foundation

struct Habit: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var icon: String
    var colorHex: String
    var frequency: HabitFrequency
    var targetCount: Int
    var completionHistory: [String: Int]
    var createdAt: Date = Date()

    enum HabitFrequency: String, Codable, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case custom = "Custom"
    }

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "star.fill",
        colorHex: String = "3B82F6",
        frequency: HabitFrequency = .daily,
        targetCount: Int = 1,
        completionHistory: [String: Int] = [:],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.frequency = frequency
        self.targetCount = targetCount
        self.completionHistory = completionHistory
        self.createdAt = createdAt
    }

    private static let keyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var currentStreak: Int {
        var streak = 0
        let calendar = Calendar.current
        var checkDate = Date()
        let today = Self.keyFormatter.string(from: Date())

        while true {
            let key = Self.keyFormatter.string(from: checkDate)
            let count = completionHistory[key] ?? 0
            if count >= targetCount {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if key == today {
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                continue
            } else {
                break
            }
            if streak > 3650 { break }
        }
        return streak
    }

    var longestStreak: Int {
        guard !completionHistory.isEmpty else { return 0 }
        let sortedKeys = completionHistory.keys.sorted()
        var longest = 0
        var current = 0
        let calendar = Calendar.current
        let formatter = Self.keyFormatter

        for (index, key) in sortedKeys.enumerated() {
            let count = completionHistory[key] ?? 0
            if count >= targetCount {
                if index == 0 {
                    current = 1
                } else {
                    let prevKey = sortedKeys[index - 1]
                    if let prevDate = formatter.date(from: prevKey),
                       let currDate = formatter.date(from: key) {
                        let diff = calendar.dateComponents([.day], from: prevDate, to: currDate).day ?? 0
                        current = diff == 1 ? current + 1 : 1
                    } else {
                        current = 1
                    }
                }
                longest = max(longest, current)
            } else {
                current = 0
            }
        }
        return longest
    }

    func todayCount() -> Int {
        completionHistory[Self.keyFormatter.string(from: Date())] ?? 0
    }

    func completedToday() -> Bool {
        todayCount() >= targetCount
    }

    func weeklyCompletionRate() -> Double {
        let calendar = Calendar.current
        var completed = 0
        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
                let key = Self.keyFormatter.string(from: date)
                if (completionHistory[key] ?? 0) >= targetCount {
                    completed += 1
                }
            }
        }
        return Double(completed) / 7.0
    }
}
