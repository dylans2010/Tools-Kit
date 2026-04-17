import Foundation

struct StreakModel: Codable {
    var currentDays: Int
    var longestDays: Int
    var lastWorkoutDate: Date?
    var workoutReminderEnabled: Bool
    var dailyCompletions: [String: Bool]

    init(
        currentDays: Int = 0,
        longestDays: Int = 0,
        lastWorkoutDate: Date? = nil,
        workoutReminderEnabled: Bool = true,
        dailyCompletions: [String: Bool] = [:]
    ) {
        self.currentDays = currentDays
        self.longestDays = longestDays
        self.lastWorkoutDate = lastWorkoutDate
        self.workoutReminderEnabled = workoutReminderEnabled
        self.dailyCompletions = dailyCompletions
    }

    mutating func registerWorkout(on date: Date) {
        let calendar = Calendar.current
        if let lastWorkoutDate {
            if calendar.isDate(lastWorkoutDate, inSameDayAs: date) {
                return
            }
            if let expectedNextDay = calendar.date(byAdding: .day, value: 1, to: lastWorkoutDate),
               calendar.isDate(expectedNextDay, inSameDayAs: date) {
                currentDays += 1
            } else {
                currentDays = 1
            }
        } else {
            currentDays = 1
        }

        longestDays = max(longestDays, currentDays)
        lastWorkoutDate = date
        markCompletion(for: date, completed: true)
    }

    mutating func evaluateMissedDay(relativeTo date: Date) {
        guard let lastWorkoutDate else { return }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: lastWorkoutDate), to: Calendar.current.startOfDay(for: date)).day ?? 0
        if days > 1 {
            currentDays = 0
        }
        markCompletion(for: date, completed: dailyCompletions[todayKey(for: date)] ?? false)
    }

    mutating func markCompletion(for date: Date, completed: Bool) {
        dailyCompletions[todayKey(for: date)] = completed
    }

    var dailyCompletionRateLast7: Double {
        let calendar = Calendar.current
        let completed = (0..<7).reduce(0) { partial, offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return partial }
            return partial + ((dailyCompletions[todayKey(for: date)] ?? false) ? 1 : 0)
        }
        return Double(completed) / 7.0
    }

    private func todayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
