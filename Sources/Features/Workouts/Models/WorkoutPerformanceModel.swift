import Foundation

struct WorkoutPerformanceModel: Identifiable, Codable {
    var id: UUID
    var date: Date
    var strengthScore: Double
    var consistencyScore: Double
    var fatigueLevel: Int
    var missedSessions: Int
    var recoveryScore: Int

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        strengthScore: Double,
        consistencyScore: Double,
        fatigueLevel: Int,
        missedSessions: Int,
        recoveryScore: Int
    ) {
        self.id = id
        self.date = date
        self.strengthScore = strengthScore
        self.consistencyScore = consistencyScore
        self.fatigueLevel = fatigueLevel
        self.missedSessions = missedSessions
        self.recoveryScore = recoveryScore
    }
}
