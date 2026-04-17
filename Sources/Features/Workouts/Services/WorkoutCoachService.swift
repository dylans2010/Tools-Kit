import Foundation

struct CoachingGuidance {
    var recovery: RecoveryScoreModel
    var recommendedDurationDelta: Int
    var note: String
}

final class WorkoutCoachService {
    func buildGuidance(
        streak: StreakModel,
        recentPerformance: [WorkoutPerformanceModel],
        recentSessions: [WorkoutSessionModel]
    ) -> CoachingGuidance {
        let missedSessions = recentPerformance.last?.missedSessions ?? 0
        let fatigue = recentPerformance.last?.fatigueLevel ?? 3
        let recentAverageFatigue = recentSessions.prefix(5).map(\.fatigueLevel).reduce(0, +) / max(recentSessions.prefix(5).count, 1)

        var score = 75
        score -= missedSessions * 8
        score -= (fatigue - 3) * 6
        score -= (recentAverageFatigue - 3) * 4
        score += min(streak.currentDays, 10)

        let guidance: WorkoutIntensityGuidance
        let durationDelta: Int
        if score < 45 {
            guidance = .recovery
            durationDelta = -15
        } else if score < 70 {
            guidance = .moderate
            durationDelta = -5
        } else {
            guidance = .intense
            durationDelta = 5
        }

        let reasons = [
            "Missed sessions: \(missedSessions)",
            "Fatigue level: \(fatigue)",
            "Current streak: \(streak.currentDays)"
        ]

        return CoachingGuidance(
            recovery: RecoveryScoreModel(score: score, guidance: guidance, reasons: reasons),
            recommendedDurationDelta: durationDelta,
            note: coachingNote(for: guidance, streak: streak.currentDays)
        )
    }

    private func coachingNote(for guidance: WorkoutIntensityGuidance, streak: Int) -> String {
        switch guidance {
        case .recovery:
            return "Focus on form, mobility, and low-load work today."
        case .moderate:
            return "Stay consistent with moderate intensity and clean technique."
        case .intense:
            return streak >= 7 ? "You are consistent—push progressive overload today." : "High readiness detected, increase intensity carefully."
        }
    }
}
