import Foundation

enum BadgeType: String, Codable, CaseIterable, Identifiable {
    case firstWorkout = "First Workout"
    case sevenDayStreak = "7 Day Streak"
    case thirtyDayStreak = "30 Day Streak"
    case goalAchieved = "Goal Achieved"
    case proteinPro = "Protein Pro"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .firstWorkout: return "figure.strengthtraining.traditional"
        case .sevenDayStreak: return "flame.fill"
        case .thirtyDayStreak: return "bolt.heart.fill"
        case .goalAchieved: return "medal.fill"
        case .proteinPro: return "fork.knife.circle.fill"
        }
    }

    var metadata: (name: String, description: String, criteria: String) {
        switch self {
        case .firstWorkout:
            return ("First Rep", "Logged your very first AI-powered workout.", "Complete at least one workout.")
        case .sevenDayStreak:
            return ("Consistency King", "Seven straight days of movement.", "Maintain a 7-day workout streak.")
        case .thirtyDayStreak:
            return ("Iron Habit", "A month of consistent effort.", "Hit a 30-day workout streak.")
        case .goalAchieved:
            return ("Goal Crusher", "Reached the body goal you set.", "Achieve your stated goal weight trend.")
        case .proteinPro:
            return ("Protein Pro", "Hit protein targets repeatedly.", "Reach your protein goal 5 days in a row.")
        }
    }
}

struct BadgeModel: Identifiable, Codable {
    var id: BadgeType
    var name: String
    var description: String
    var criteria: String
    var unlockedAt: Date?

    init(id: BadgeType, unlockedAt: Date? = nil) {
        self.id = id
        let meta = id.metadata
        self.name = meta.name
        self.description = meta.description
        self.criteria = meta.criteria
        self.unlockedAt = unlockedAt
    }

    var isUnlocked: Bool { unlockedAt != nil }

    private enum CodingKeys: String, CodingKey {
        case id, name, description, criteria, unlockedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(BadgeType.self, forKey: .id) ?? .firstWorkout
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? id.metadata.name
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? id.metadata.description
        criteria = try container.decodeIfPresent(String.self, forKey: .criteria) ?? id.metadata.criteria
        unlockedAt = try container.decodeIfPresent(Date.self, forKey: .unlockedAt)
    }
}
