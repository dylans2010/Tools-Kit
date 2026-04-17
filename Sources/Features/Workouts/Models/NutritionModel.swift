import Foundation

enum MealSourceType: String, Codable, CaseIterable, Identifiable {
    case voice
    case image
    case manual

    var id: String { rawValue }
}

enum FoodCategory: String, Codable, CaseIterable, Identifiable {
    case protein
    case carbs
    case vegetables
    case drinks
    case fats
    case mixed

    var id: String { rawValue }
}

struct DetectedFoodItem: Identifiable, Codable {
    var id: UUID
    var name: String
    var category: FoodCategory
    var portionDescription: String
    var estimatedCalories: Int

    init(
        id: UUID = UUID(),
        name: String,
        category: FoodCategory,
        portionDescription: String,
        estimatedCalories: Int
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.portionDescription = portionDescription
        self.estimatedCalories = estimatedCalories
    }
}

struct MealRecord: Identifiable, Codable {
    var id: UUID
    var name: String
    var calories: Int
    var proteinGrams: Double
    var carbsGrams: Double
    var fatsGrams: Double
    var summary: String
    var consumedAt: Date
    var sourceType: MealSourceType
    var rawInput: String
    var detectedItems: [DetectedFoodItem]
    var timestamp: Date

    init(
        id: UUID = UUID(),
        name: String,
        calories: Int,
        proteinGrams: Double,
        carbsGrams: Double,
        fatsGrams: Double,
        summary: String,
        consumedAt: Date = Date(),
        sourceType: MealSourceType = .manual,
        rawInput: String = "",
        detectedItems: [DetectedFoodItem] = [],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatsGrams = fatsGrams
        self.summary = summary
        self.consumedAt = consumedAt
        self.sourceType = sourceType
        self.rawInput = rawInput
        self.detectedItems = detectedItems
        self.timestamp = timestamp
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, calories, proteinGrams, carbsGrams, fatsGrams, summary, consumedAt, sourceType, rawInput, detectedItems, timestamp
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        calories = try container.decode(Int.self, forKey: .calories)
        proteinGrams = try container.decode(Double.self, forKey: .proteinGrams)
        carbsGrams = try container.decode(Double.self, forKey: .carbsGrams)
        fatsGrams = try container.decode(Double.self, forKey: .fatsGrams)
        summary = try container.decode(String.self, forKey: .summary)
        consumedAt = try container.decodeIfPresent(Date.self, forKey: .consumedAt) ?? Date()
        sourceType = try container.decodeIfPresent(MealSourceType.self, forKey: .sourceType) ?? .manual
        rawInput = try container.decodeIfPresent(String.self, forKey: .rawInput) ?? name
        detectedItems = try container.decodeIfPresent([DetectedFoodItem].self, forKey: .detectedItems) ?? []
        timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? consumedAt
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
