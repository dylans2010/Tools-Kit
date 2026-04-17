import Foundation

struct WorkoutModel: Identifiable, Codable {
    var id: UUID
    var date: Date
    var title: String
    var difficulty: String
    var estimatedDurationMinutes: Int
    var exercises: [ExerciseModel]
    var notes: String
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        title: String,
        difficulty: String = "medium",
        estimatedDurationMinutes: Int,
        exercises: [ExerciseModel],
        notes: String = "",
        completedAt: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.difficulty = difficulty
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

    private enum CodingKeys: String, CodingKey {
        case id, date, title, difficulty, estimatedDurationMinutes, exercises, notes, completedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Workout"
        difficulty = try container.decodeIfPresent(String.self, forKey: .difficulty) ?? "medium"
        estimatedDurationMinutes = try container.decodeIfPresent(Int.self, forKey: .estimatedDurationMinutes) ?? 0
        exercises = try container.decodeIfPresent([ExerciseModel].self, forKey: .exercises) ?? []
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
    }
}
