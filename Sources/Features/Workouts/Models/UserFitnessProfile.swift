import Foundation

struct UserFitnessProfile: Codable {
    enum FitnessGoal: String, Codable, CaseIterable, Identifiable {
        case gainMuscle = "Gain muscle"
        case loseWeight = "Lose weight"
        case maintain = "Maintain"
        case gainWeight = "Gain weight"

        var id: String { rawValue }
    }

    enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
        case sedentary = "Sedentary"
        case lightlyActive = "Lightly active"
        case moderatelyActive = "Moderately active"
        case veryActive = "Very active"

        var id: String { rawValue }

        var multiplier: Double {
            switch self {
            case .sedentary: return 1.2
            case .lightlyActive: return 1.375
            case .moderatelyActive: return 1.55
            case .veryActive: return 1.725
            }
        }
    }

    var weightKg: Double
    var heightCm: Double
    var age: Int?
    var goal: FitnessGoal
    var activityLevel: ActivityLevel
}
