import Foundation

struct ExerciseModel: Identifiable, Codable, Sendable {
    var id: UUID
    var name: String
    var sets: Int
    var reps: Int
    var durationMinutes: Int
    var restSeconds: Int
    var muscleGroup: String
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        name: String,
        sets: Int,
        reps: Int,
        durationMinutes: Int,
        restSeconds: Int,
        muscleGroup: String = "",
        isCompleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.durationMinutes = durationMinutes
        self.restSeconds = restSeconds
        self.muscleGroup = muscleGroup
        self.isCompleted = isCompleted
    }

    private enum CodingKeys: String, CodingKey, Sendable {
        case id, name, sets, reps, durationMinutes, restSeconds, muscleGroup, isCompleted
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        sets = try container.decodeIfPresent(Int.self, forKey: .sets) ?? 0
        reps = try container.decodeIfPresent(Int.self, forKey: .reps) ?? 0
        durationMinutes = try container.decodeIfPresent(Int.self, forKey: .durationMinutes) ?? 0
        restSeconds = try container.decodeIfPresent(Int.self, forKey: .restSeconds) ?? 0
        muscleGroup = try container.decodeIfPresent(String.self, forKey: .muscleGroup) ?? ""
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
    }
}
