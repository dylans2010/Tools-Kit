import Foundation

struct ExerciseModel: Identifiable, Codable {
    var id: UUID
    var name: String
    var sets: Int
    var reps: Int
    var durationMinutes: Int
    var restSeconds: Int
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        name: String,
        sets: Int,
        reps: Int,
        durationMinutes: Int,
        restSeconds: Int,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.durationMinutes = durationMinutes
        self.restSeconds = restSeconds
        self.isCompleted = isCompleted
    }
}
