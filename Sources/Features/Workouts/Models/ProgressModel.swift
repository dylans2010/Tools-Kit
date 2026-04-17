import Foundation

struct ProgressModel: Identifiable, Codable {
    var id: UUID
    var date: Date
    var weightKg: Double?
    var workoutsCompleted: Int
    var caloriesBurned: Double
    var caloriesConsumed: Int
    var steps: Int

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        weightKg: Double? = nil,
        workoutsCompleted: Int = 0,
        caloriesBurned: Double = 0,
        caloriesConsumed: Int = 0,
        steps: Int = 0
    ) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.workoutsCompleted = workoutsCompleted
        self.caloriesBurned = caloriesBurned
        self.caloriesConsumed = caloriesConsumed
        self.steps = steps
    }
}
