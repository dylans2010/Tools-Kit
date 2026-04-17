import Foundation

struct StreakModel: Codable {
    var currentDays: Int
    var longestDays: Int
    var lastWorkoutDate: Date?

    init(currentDays: Int = 0, longestDays: Int = 0, lastWorkoutDate: Date? = nil) {
        self.currentDays = currentDays
        self.longestDays = longestDays
        self.lastWorkoutDate = lastWorkoutDate
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
    }

    mutating func evaluateMissedDay(relativeTo date: Date) {
        guard let lastWorkoutDate else { return }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: lastWorkoutDate), to: Calendar.current.startOfDay(for: date)).day ?? 0
        if days > 1 {
            currentDays = 0
        }
    }
}
