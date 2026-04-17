import Foundation

enum WorkoutIntensityGuidance: String, Codable, CaseIterable, Identifiable {
    case recovery = "Recovery"
    case moderate = "Moderate"
    case intense = "Intense"

    var id: String { rawValue }
}

struct RecoveryScoreModel: Codable {
    var score: Int
    var guidance: WorkoutIntensityGuidance
    var reasons: [String]

    init(score: Int, guidance: WorkoutIntensityGuidance, reasons: [String]) {
        self.score = min(max(score, 0), 100)
        self.guidance = guidance
        self.reasons = reasons
    }
}
