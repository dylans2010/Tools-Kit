import Foundation

private struct WorkoutAIExerciseResponse: Codable, Identifiable {
    let id: UUID
    let name: String
    let sets: Int
    let reps: Int
    let restSeconds: Int
    let muscleGroup: String

    init(
        id: UUID = UUID(),
        name: String,
        sets: Int,
        reps: Int,
        restSeconds: Int,
        muscleGroup: String
    ) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.restSeconds = restSeconds
        self.muscleGroup = muscleGroup
    }
}

private struct WorkoutAIResponse: Codable {
    let workoutName: String
    let duration: Int
    let difficulty: String
    let exercises: [WorkoutAIExerciseResponse]
}

final class WorkoutAIService {
    private let ai = AIService.shared
    private let decoder = AIResponseDecoder()
    private let schemaString = """
    {
      "type": "object",
      "required": ["workoutName", "duration", "difficulty", "exercises"],
      "properties": {
        "workoutName": {"type": "string"},
        "duration": {"type": "integer"},
        "difficulty": {"type": "string", "enum": ["easy", "medium", "hard"]},
        "exercises": {
          "type": "array",
          "minItems": 4,
          "items": {
            "type": "object",
            "required": ["name", "sets", "reps", "restSeconds", "muscleGroup"],
            "properties": {
              "name": {"type": "string"},
              "sets": {"type": "integer"},
              "reps": {"type": "integer"},
              "restSeconds": {"type": "integer"},
              "muscleGroup": {"type": "string"}
            }
          }
        }
      }
    }
    """

    private let schema: AIJSONType = .object([
        "workoutName": .string,
        "duration": .int,
        "difficulty": .string,
        "exercises": .array(.object([
            "name": .string,
            "sets": .int,
            "reps": .int,
            "restSeconds": .int,
            "muscleGroup": .string
        ]))
    ])

    func generateWorkout(
        profile: UserFitnessProfile,
        progress: [ProgressModel],
        streak: StreakModel,
        nutrition: NutritionModel,
        recentWorkouts: [WorkoutModel],
        performances: [WorkoutPerformanceModel],
        guidance: CoachingGuidance,
        preferredDuration: Int
    ) async -> Result<WorkoutModel, AIResponseDecoderError> {
        let prompt = buildPrompt(
            profile: profile,
            progress: progress,
            streak: streak,
            nutrition: nutrition,
            recentWorkouts: recentWorkouts,
            performances: performances,
            guidance: guidance,
            preferredDuration: preferredDuration
        )

        var attempt = 0
        var lastError: AIResponseDecoderError?

        while attempt < 3 {
            attempt += 1
            do {
                let json = try await ai.generateStructuredJSON(
                    prompt: promptWithVariation(prompt, attempt: attempt),
                    jsonSchema: schemaString,
                    preferredModel: "openrouter/free"
                )

                let decoded = try decoder.decode(WorkoutAIResponse.self, from: json, schema: schema)
                if isDuplicate(response: decoded, recentWorkouts: recentWorkouts) {
                    lastError = .decodingFailed("AI returned a workout too similar to recent sessions.")
                    continue
                }

                let mapped = map(response: decoded, guidance: guidance)
                return .success(mapped)
            } catch let error as AIResponseDecoderError {
                lastError = error
            } catch {
                lastError = .decodingFailed(error.localizedDescription)
            }
        }

        return .failure(lastError ?? .invalidJSON)
    }

    private func buildPrompt(
        profile: UserFitnessProfile,
        progress: [ProgressModel],
        streak: StreakModel,
        nutrition: NutritionModel,
        recentWorkouts: [WorkoutModel],
        performances: [WorkoutPerformanceModel],
        guidance: CoachingGuidance,
        preferredDuration: Int
    ) -> String {
        let weeklyWorkouts = progress.suffix(7).reduce(0) { $0 + $1.workoutsCompleted }
        let latestPerformance = performances.first
        let recentSummary = recentWorkouts.prefix(3).map { workout in
            let exerciseNames = workout.exercises.prefix(4).map(\.name).joined(separator: ", ")
            return "- \(workout.title) • \(exerciseNames)"
        }.joined(separator: "\n")

        return """
        Build a personalized workout plan for today. Respond with VALID JSON only.

        User profile:
        - goal: \(profile.goal.rawValue)
        - activity: \(profile.activityLevel.rawValue)
        - weightKg: \(profile.weightKg)
        - heightCm: \(profile.heightCm)
        - age: \(profile.age ?? 30)

        Training context:
        - streak days: \(streak.currentDays)
        - workouts in last 7 days: \(weeklyWorkouts)
        - preferred duration minutes: \(preferredDuration)
        - current recovery score: \(guidance.recovery.score) (\(guidance.recovery.guidance.rawValue))
        - fatigue level: \(latestPerformance?.fatigueLevel ?? 3)
        - recent calories consumed today: \(nutrition.caloriesConsumed) / \(nutrition.calorieGoal)

        Recent workouts (avoid repeating exercise selections):
        \(recentSummary.isEmpty ? "- none" : recentSummary)

        Requirements:
        - Vary exercises and muscle groups from recent workouts.
        - Match difficulty to recovery/fatigue state.
        - Provide realistic set, rep, and rest values.
        - Duration should be close to preferred duration.
        """
    }

    private func promptWithVariation(_ base: String, attempt: Int) -> String {
        if attempt <= 1 { return base }
        return base + "\nAttempt \(attempt): Change primary lifts or conditioning blocks to avoid repetition and respect recovery."
    }

    private func isDuplicate(response: WorkoutAIResponse, recentWorkouts: [WorkoutModel]) -> Bool {
        guard let recent = recentWorkouts.first else { return false }
        let incoming = Set(response.exercises.map { $0.name.lowercased() })
        let existing = Set(recent.exercises.map { $0.name.lowercased() })
        let overlap = Double(incoming.intersection(existing).count)
        let baseline = max(Double(incoming.count), 1)
        return overlap / baseline >= 0.6
    }

    private func map(response: WorkoutAIResponse, guidance: CoachingGuidance) -> WorkoutModel {
        let perExerciseDuration = max(5, response.duration / max(response.exercises.count, 1))
        let exercises = response.exercises.map {
            ExerciseModel(
                name: $0.name,
                sets: $0.sets,
                reps: $0.reps,
                durationMinutes: perExerciseDuration,
                restSeconds: $0.restSeconds,
                muscleGroup: $0.muscleGroup,
                isCompleted: false
            )
        }

        let notes = "AI-generated \(response.difficulty) session. Guidance: \(guidance.note)"
        return WorkoutModel(
            date: Date(),
            title: response.workoutName,
            difficulty: response.difficulty,
            estimatedDurationMinutes: response.duration,
            exercises: exercises,
            notes: notes
        )
    }
}
