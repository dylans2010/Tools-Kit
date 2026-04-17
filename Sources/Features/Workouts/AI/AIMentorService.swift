import Foundation

final class AIMentorService {
    private let contextBuilder = AIMentorContextBuilder()

    func respond(
        to prompt: String,
        imageData: Data?,
        profile: UserFitnessProfile?,
        todayWorkout: WorkoutModel?,
        nutrition: NutritionModel,
        streak: StreakModel,
        badges: [BadgeModel],
        progress: [ProgressModel],
        performances: [WorkoutPerformanceModel],
        healthData: HealthImportedData,
        memory: [MentorMessageModel]
    ) -> MentorMessageModel {
        let context = contextBuilder.build(
            profile: profile,
            todayWorkout: todayWorkout,
            nutrition: nutrition,
            streak: streak,
            badges: badges,
            progress: progress,
            performances: performances,
            healthData: healthData,
            messages: memory
        )

        let lower = prompt.lowercased()
        let recommendation: String
        if lower.contains("meal") || lower.contains("nutrition") {
            recommendation = "Based on your log, prioritize protein at your next meal and keep carbs around your workouts."
        } else if lower.contains("fatigue") || lower.contains("tired") {
            recommendation = "Your recent pattern suggests recovery focus: shorter session, lower intensity, extra hydration and sleep."
        } else if lower.contains("workout") || lower.contains("plan") {
            recommendation = "Use today's workout plan, aim for progressive overload on your first two compound movements."
        } else {
            recommendation = "Stay consistent with workouts, hit your calories/protein targets, and review progress weekly."
        }

        let imageHint: String?
        if imageData?.isEmpty == false {
            imageHint = "Image context included"
        } else {
            imageHint = nil
        }

        let text = [
            recommendation,
            "",
            "Context snapshot:",
            context.profileSummary,
            context.workoutSummary,
            context.nutritionSummary,
            context.streakSummary
        ].joined(separator: "\n")

        return MentorMessageModel(role: .assistant, text: text, imageHint: imageHint)
    }
}
