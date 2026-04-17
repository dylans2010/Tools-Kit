import Foundation

struct ExerciseSetLog: Identifiable, Codable {
    var id: UUID
    var setNumber: Int
    var reps: Int
    var weightKg: Double

    init(id: UUID = UUID(), setNumber: Int, reps: Int, weightKg: Double) {
        self.id = id
        self.setNumber = setNumber
        self.reps = reps
        self.weightKg = weightKg
    }
}

struct ExerciseSessionLog: Identifiable, Codable {
    var id: UUID
    var exerciseName: String
    var durationMinutes: Int
    var sets: [ExerciseSetLog]

    init(id: UUID = UUID(), exerciseName: String, durationMinutes: Int = 0, sets: [ExerciseSetLog] = []) {
        self.id = id
        self.exerciseName = exerciseName
        self.durationMinutes = durationMinutes
        self.sets = sets
    }

    var totalVolume: Double {
        sets.reduce(0) { $0 + (Double($1.reps) * $1.weightKg) }
    }
}

struct WorkoutSessionModel: Identifiable, Codable {
    var id: UUID
    var workoutTitle: String
    var startedAt: Date
    var endedAt: Date?
    var fatigueLevel: Int
    var exerciseLogs: [ExerciseSessionLog]
    var notes: String

    init(
        id: UUID = UUID(),
        workoutTitle: String,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        fatigueLevel: Int = 3,
        exerciseLogs: [ExerciseSessionLog] = [],
        notes: String = ""
    ) {
        self.id = id
        self.workoutTitle = workoutTitle
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.fatigueLevel = fatigueLevel
        self.exerciseLogs = exerciseLogs
        self.notes = notes
    }

    var durationMinutes: Int {
        guard let endedAt else { return 0 }
        return max(Int(endedAt.timeIntervalSince(startedAt) / 60), 0)
    }

    var totalVolume: Double {
        exerciseLogs.reduce(0) { $0 + $1.totalVolume }
    }
}
