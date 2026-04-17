import Foundation

struct WorkoutModel: Identifiable, Codable {
    var id: UUID
    var date: Date
    var title: String
    var estimatedDurationMinutes: Int
    var exercises: [ExerciseModel]
    var notes: String
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        title: String,
        estimatedDurationMinutes: Int,
        exercises: [ExerciseModel],
        notes: String = "",
        completedAt: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.exercises = exercises
        self.notes = notes
        self.completedAt = completedAt
    }

    var completionRate: Double {
        guard !exercises.isEmpty else { return 0 }
        let done = exercises.filter(\.isCompleted).count
        return Double(done) / Double(exercises.count)
    }

    var isCompleted: Bool {
        exercises.allSatisfy(\.isCompleted)
    }
}
