import Foundation

struct WorkoutUserPlan: Codable {
    struct PlanExercise: Codable, Identifiable {
        let id: UUID
        let name: String
        let sets: Int
        let reps: Int
        let restSeconds: Int
        let durationMinutes: Int
        let rationale: String

        init(
            id: UUID = UUID(),
            name: String,
            sets: Int,
            reps: Int,
            restSeconds: Int,
            durationMinutes: Int,
            rationale: String
        ) {
            self.id = id
            self.name = name
            self.sets = sets
            self.reps = reps
            self.restSeconds = restSeconds
            self.durationMinutes = durationMinutes
            self.rationale = rationale
        }
    }

    let title: String
    let intensity: String
    let notes: String
    let recoveryAdvice: [String]
    let exercises: [PlanExercise]

    var workoutModel: WorkoutModel {
        WorkoutModel(
            date: Date(),
            title: title,
            estimatedDurationMinutes: max(20, exercises.reduce(0) { $0 + $1.durationMinutes }),
            exercises: exercises.map {
                ExerciseModel(
                    name: $0.name,
                    sets: $0.sets,
                    reps: $0.reps,
                    durationMinutes: $0.durationMinutes,
                    restSeconds: $0.restSeconds,
                    isCompleted: false
                )
            },
            notes: ([notes] + recoveryAdvice).joined(separator: "\n• ")
        )
    }
}
