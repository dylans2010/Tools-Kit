import Foundation

struct MealRecord: Identifiable, Codable {
    var id: UUID
    var name: String
    var calories: Int
    var proteinGrams: Double
    var carbsGrams: Double
    var fatsGrams: Double
    var summary: String
    var consumedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        calories: Int,
        proteinGrams: Double,
        carbsGrams: Double,
        fatsGrams: Double,
        summary: String,
        consumedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatsGrams = fatsGrams
        self.summary = summary
        self.consumedAt = consumedAt
    }
}

struct NutritionModel: Codable {
    var date: Date
    var calorieGoal: Int
    var proteinGoal: Double
    var carbsGoal: Double
    var fatsGoal: Double
    var meals: [MealRecord]

    init(
        date: Date = Date(),
        calorieGoal: Int = 2200,
        proteinGoal: Double = 150,
        carbsGoal: Double = 230,
        fatsGoal: Double = 70,
        meals: [MealRecord] = []
    ) {
        self.date = date
        self.calorieGoal = calorieGoal
        self.proteinGoal = proteinGoal
        self.carbsGoal = carbsGoal
        self.fatsGoal = fatsGoal
        self.meals = meals
    }

    var caloriesConsumed: Int { meals.reduce(0) { $0 + $1.calories } }
    var remainingCalories: Int { max(calorieGoal - caloriesConsumed, 0) }
    var proteinConsumed: Double { meals.reduce(0) { $0 + $1.proteinGrams } }
    var carbsConsumed: Double { meals.reduce(0) { $0 + $1.carbsGrams } }
    var fatsConsumed: Double { meals.reduce(0) { $0 + $1.fatsGrams } }
}
