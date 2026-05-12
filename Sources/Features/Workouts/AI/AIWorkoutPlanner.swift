import Foundation

final class AIWorkoutPlanner {
    private let ai = AIService.shared

    private let modelID = "openai/gpt-oss-120b:free"

    @MainActor
    func generatePlan(
        profile: UserFitnessProfile,
        progress: [ProgressModel],
        streak: StreakModel,
        nutrition: NutritionModel,
        previousWorkout: WorkoutModel?
    ) async -> WorkoutUserPlan {
        let context = WorkoutPlannerContext(profile: profile, progress: progress, streak: streak, nutrition: nutrition, previousWorkout: previousWorkout)

        do {
            let json = try await ai.generateStructuredJSON(
                prompt: context.prompt,
                jsonSchema: WorkoutPlannerContext.responseSchema,
                preferredModel: modelID
            )
            if let plan = try? JSONDecoder().decode(WorkoutUserPlan.self, from: Data(json.utf8)) {
                return plan
            }
        } catch {
            // fallback below
        }

        return context.fallbackPlan
    }
}

private struct WorkoutPlannerContext: Sendable {
    let profile: UserFitnessProfile
    let progress: [ProgressModel]
    let streak: StreakModel
    let nutrition: NutritionModel
    let previousWorkout: WorkoutModel?

    var prompt: String {
        """
        Build a fully personalized workout for today.

        User profile:
        - Weight: \(profile.weightKg) kg
        - Height: \(profile.heightCm) cm
        - Age: \(profile.age ?? 30)
        - Goal: \(profile.goal.rawValue)
        - Activity level: \(profile.activityLevel.rawValue)

        Training signals:
        - Current streak: \(streak.currentDays)
        - Workouts this week: \(progress.suffix(7).reduce(0) { $0 + $1.workoutsCompleted })
        - Daily calorie goal: \(nutrition.calorieGoal)
        - Calories consumed today: \(nutrition.caloriesConsumed)
        - Last workout title: \(previousWorkout?.title ?? "None")

        Return strict JSON only.
        """
    }

    static let responseSchema = """
    {
      "type": "object",
      "required": ["title", "intensity", "notes", "recoveryAdvice", "exercises"],
      "properties": {
        "title": {"type": "string"},
        "intensity": {"type": "string"},
        "notes": {"type": "string"},
        "recoveryAdvice": {"type": "array", "items": {"type": "string"}},
        "exercises": {
          "type": "array",
          "minItems": 4,
          "items": {
            "type": "object",
            "required": ["name", "sets", "reps", "restSeconds", "durationMinutes", "rationale"],
            "properties": {
              "name": {"type": "string"},
              "sets": {"type": "integer"},
              "reps": {"type": "integer"},
              "restSeconds": {"type": "integer"},
              "durationMinutes": {"type": "integer"},
              "rationale": {"type": "string"}
            }
          }
        }
      }
    }
    """

    var fallbackPlan: WorkoutUserPlan {
        let weeklyLoad = progress.suffix(7).reduce(0) { $0 + $1.workoutsCompleted }
        let intensity = weeklyLoad >= 4 ? "high" : (weeklyLoad >= 2 ? "moderate" : "build-up")
        let baseSets = intensity == "high" ? 5 : (intensity == "moderate" ? 4 : 3)

        return WorkoutUserPlan(
            title: "Adaptive \(profile.goal.rawValue) Session",
            intensity: intensity,
            notes: "Personalized fallback plan generated from profile, streak, and nutrition adherence.",
            recoveryAdvice: [
                "Hydrate to at least 2.5L today.",
                "Prioritize 7-9h sleep for recovery.",
                "Consume protein within 2h post-workout."
            ],
            exercises: [
                .init(name: "Warm-up mobility flow", sets: 1, reps: 1, restSeconds: 20, durationMinutes: 8, rationale: "Prepare joints and reduce injury risk."),
                .init(name: "Primary compound lift", sets: baseSets, reps: 8, restSeconds: 90, durationMinutes: 12, rationale: "Drive main adaptation for \(profile.goal.rawValue)."),
                .init(name: "Secondary strength block", sets: baseSets, reps: 10, restSeconds: 75, durationMinutes: 10, rationale: "Build strength endurance."),
                .init(name: "Accessory hypertrophy circuit", sets: 3, reps: 12, restSeconds: 45, durationMinutes: 12, rationale: "Support weak points and muscle balance."),
                .init(name: "Conditioning finisher", sets: 4, reps: 1, restSeconds: 30, durationMinutes: 8, rationale: "Improve work capacity and heart health."),
                .init(name: "Cooldown + breathwork", sets: 1, reps: 1, restSeconds: 0, durationMinutes: 6, rationale: "Promote recovery and parasympathetic reset.")
            ]
        )
    }
}
