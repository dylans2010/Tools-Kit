import Foundation

struct AnalyticsSummary: Sendable {
    var weightTrend: [ProgressModel]
    var consistencyTrend: [ProgressModel]
    var strengthTrend: [WorkoutPerformanceModel]
    var insights: [String]
}

final class AnalyticsService {
    func buildSummary(progress: [ProgressModel], performances: [WorkoutPerformanceModel]) -> AnalyticsSummary {
        let recentProgress = Array(progress.suffix(30))
        let recentPerformance = Array(performances.suffix(30))

        var insights: [String] = []
        if let first = recentProgress.compactMap(\.weightKg).first,
           let last = recentProgress.compactMap(\.weightKg).last {
            let delta = last - first
            let direction = delta > 0 ? "up" : "down"
            insights.append("Weight trend is \(direction) by \(String(format: "%.1f", abs(delta))) kg.")
        }

        let workoutCount = recentProgress.reduce(0) { $0 + $1.workoutsCompleted }
        if workoutCount < 10 {
            insights.append("Consistency is low this month; target at least 3 sessions weekly.")
        } else {
            insights.append("Consistency is strong with \(workoutCount) workout completions this month.")
        }

        if let lastStrength = recentPerformance.last?.strengthScore {
            insights.append("Current strength score: \(Int(lastStrength))/100.")
        }

        if insights.isEmpty {
            insights.append("Log workouts and meals to unlock richer analytics.")
        }

        return AnalyticsSummary(
            weightTrend: recentProgress,
            consistencyTrend: recentProgress,
            strengthTrend: recentPerformance,
            insights: insights
        )
    }
}
