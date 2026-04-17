import Foundation

enum BadgeType: String, Codable, CaseIterable, Identifiable {
    case firstWorkout = "First Workout"
    case sevenDayStreak = "7 Day Streak"
    case thirtyDayStreak = "30 Day Streak"
    case goalAchieved = "Goal Achieved"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .firstWorkout: return "figure.strengthtraining.traditional"
        case .sevenDayStreak: return "flame.fill"
        case .thirtyDayStreak: return "bolt.heart.fill"
        case .goalAchieved: return "medal.fill"
        }
    }
}

struct BadgeModel: Identifiable, Codable {
    var id: BadgeType
    var unlockedAt: Date?

    init(id: BadgeType, unlockedAt: Date? = nil) {
        self.id = id
        self.unlockedAt = unlockedAt
    }

    var isUnlocked: Bool { unlockedAt != nil }
}
