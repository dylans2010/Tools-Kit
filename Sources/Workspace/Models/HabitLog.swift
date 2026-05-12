import Foundation

struct HabitLog: Identifiable, Codable, Sendable {
    var id: UUID
    var habitID: UUID
    var date: Date
    var completedCount: Int

    init(id: UUID = UUID(), habitID: UUID, date: Date = Date(), completedCount: Int = 1) {
        self.id = id
        self.habitID = habitID
        self.date = date
        self.completedCount = completedCount
    }
}
