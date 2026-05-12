import Foundation

struct AIMentorContext: Sendable {
    var profileSummary: String
    var workoutSummary: String
    var nutritionSummary: String
    var streakSummary: String
    var badgeSummary: String
    var progressSummary: String
    var healthSummary: String
    var recentMessages: [MentorMessageModel]

    var flattened: String {
        [
            profileSummary,
            workoutSummary,
            nutritionSummary,
            streakSummary,
            badgeSummary,
            progressSummary,
            healthSummary
        ]
        .joined(separator: "\n")
    }
}

final class AIMentorContextBuilder {
    func build(
        profile: UserFitnessProfile?,
        todayWorkout: WorkoutModel?,
        nutrition: NutritionModel,
        streak: StreakModel,
        badges: [BadgeModel],
        progress: [ProgressModel],
        performances: [WorkoutPerformanceModel],
        healthData: HealthImportedData,
        messages: [MentorMessageModel]
    ) -> AIMentorContext {
        let profileSummary: String
        if let profile {
            profileSummary = "Profile: goal=\(profile.goal.rawValue), weight=\(Int(profile.weightKg))kg, activity=\(profile.activityLevel.rawValue)."
        } else {
            profileSummary = "Profile: not configured."
        }

        let workoutSummary: String
        if let workout = todayWorkout {
            workoutSummary = "Workout: \(workout.title), completion=\(Int(workout.completionRate * 100))%, exercises=\(workout.exercises.count)."
        } else {
            workoutSummary = "Workout: no plan generated."
        }

        let nutritionSummary = "Nutrition: \(nutrition.caloriesConsumed)/\(nutrition.calorieGoal) kcal, P\(Int(nutrition.proteinConsumed))/\(Int(nutrition.proteinGoal)), C\(Int(nutrition.carbsConsumed))/\(Int(nutrition.carbsGoal)), F\(Int(nutrition.fatsConsumed))/\(Int(nutrition.fatsGoal))."
        let streakSummary = "Streaks: current \(streak.currentDays), longest \(streak.longestDays), daily completion \(Int(streak.dailyCompletionRateLast7 * 100))%."
        let unlocked = badges.filter(\.isUnlocked).count
        let badgeSummary = "Badges: \(unlocked)/\(badges.count) unlocked."

        let lastProgress = progress.last
        let lastPerformance = performances.last
        let progressSummary = "Progress: workouts today=\(lastProgress?.workoutsCompleted ?? 0), steps=\(lastProgress?.steps ?? 0), strength score=\(Int(lastPerformance?.strengthScore ?? 0))."

        let healthSummary = "Health: steps=\(healthData.steps), calories burned=\(Int(healthData.caloriesBurned)), workouts=\(healthData.workouts), avg HR=\(Int(healthData.averageHeartRate ?? 0))."

        return AIMentorContext(
            profileSummary: profileSummary,
            workoutSummary: workoutSummary,
            nutritionSummary: nutritionSummary,
            streakSummary: streakSummary,
            badgeSummary: badgeSummary,
            progressSummary: progressSummary,
            healthSummary: healthSummary,
            recentMessages: Array(messages.suffix(10))
        )
    }
}
