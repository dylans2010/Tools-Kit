import Foundation

struct ProgressModel: Identifiable, Codable, Sendable {
    var id: UUID
    var date: Date
    var weightKg: Double?
    var workoutsCompleted: Int
    var caloriesBurned: Double
    var caloriesConsumed: Int
    var proteinConsumed: Double
    var carbsConsumed: Double
    var fatsConsumed: Double
    var steps: Int

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        weightKg: Double? = nil,
        workoutsCompleted: Int = 0,
        caloriesBurned: Double = 0,
        caloriesConsumed: Int = 0,
        proteinConsumed: Double = 0,
        carbsConsumed: Double = 0,
        fatsConsumed: Double = 0,
        steps: Int = 0
    ) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.workoutsCompleted = workoutsCompleted
        self.caloriesBurned = caloriesBurned
        self.caloriesConsumed = caloriesConsumed
        self.proteinConsumed = proteinConsumed
        self.carbsConsumed = carbsConsumed
        self.fatsConsumed = fatsConsumed
        self.steps = steps
    }

    private enum CodingKeys: String, CodingKey, Sendable {
        case id, date, weightKg, workoutsCompleted, caloriesBurned, caloriesConsumed, proteinConsumed, carbsConsumed, fatsConsumed, steps
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        weightKg = try container.decodeIfPresent(Double.self, forKey: .weightKg)
        workoutsCompleted = try container.decodeIfPresent(Int.self, forKey: .workoutsCompleted) ?? 0
        caloriesBurned = try container.decodeIfPresent(Double.self, forKey: .caloriesBurned) ?? 0
        caloriesConsumed = try container.decodeIfPresent(Int.self, forKey: .caloriesConsumed) ?? 0
        proteinConsumed = try container.decodeIfPresent(Double.self, forKey: .proteinConsumed) ?? 0
        carbsConsumed = try container.decodeIfPresent(Double.self, forKey: .carbsConsumed) ?? 0
        fatsConsumed = try container.decodeIfPresent(Double.self, forKey: .fatsConsumed) ?? 0
        steps = try container.decodeIfPresent(Int.self, forKey: .steps) ?? 0
    }
}
