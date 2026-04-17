import Foundation

enum MealSourceType: String, Codable, CaseIterable, Identifiable {
    case voice
    case image
    case manual

    var id: String { rawValue }
}

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case snack

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

    private enum CodingKeys: String, CodingKey {
        case id, name, category, portionDescription, estimatedCalories, portion
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Food"
        category = try container.decodeIfPresent(FoodCategory.self, forKey: .category) ?? .mixed
        if let portion = try container.decodeIfPresent(String.self, forKey: .portion) {
            portionDescription = portion
        } else {
            portionDescription = try container.decodeIfPresent(String.self, forKey: .portionDescription) ?? "1 serving"
        }
        estimatedCalories = try container.decodeIfPresent(Int.self, forKey: .estimatedCalories) ?? 0
    }
}

struct MealRecord: Identifiable, Codable {
    var id: UUID
    var mealType: MealType
    var name: String
    var calories: Int
    var proteinGrams: Double
    var carbsGrams: Double
    var fatsGrams: Double
    var summary: String
    var insights: [String]
    var consumedAt: Date
    var sourceType: MealSourceType
    var rawInput: String
    var detectedItems: [DetectedFoodItem]
    var timestamp: Date
    var imagePreviewData: Data?

    init(
        id: UUID = UUID(),
        mealType: MealType = .breakfast,
        name: String,
        calories: Int,
        proteinGrams: Double,
        carbsGrams: Double,
        fatsGrams: Double,
        summary: String,
        insights: [String] = [],
        consumedAt: Date = Date(),
        sourceType: MealSourceType = .manual,
        rawInput: String = "",
        detectedItems: [DetectedFoodItem] = [],
        timestamp: Date = Date(),
        imagePreviewData: Data? = nil
    ) {
        self.id = id
        self.mealType = mealType
        self.name = name
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatsGrams = fatsGrams
        self.summary = summary
        self.insights = insights
        self.consumedAt = consumedAt
        self.sourceType = sourceType
        self.rawInput = rawInput
        self.detectedItems = detectedItems
        self.timestamp = timestamp
        self.imagePreviewData = imagePreviewData
    }

    private enum CodingKeys: String, CodingKey {
        case id, mealType, name, calories, proteinGrams, carbsGrams, fatsGrams, summary, insights, consumedAt, sourceType, rawInput, detectedItems, timestamp, imagePreviewData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        mealType = try container.decodeIfPresent(MealType.self, forKey: .mealType) ?? .breakfast
        name = try container.decode(String.self, forKey: .name)
        calories = try container.decode(Int.self, forKey: .calories)
        proteinGrams = try container.decode(Double.self, forKey: .proteinGrams)
        carbsGrams = try container.decode(Double.self, forKey: .carbsGrams)
        fatsGrams = try container.decode(Double.self, forKey: .fatsGrams)
        summary = try container.decode(String.self, forKey: .summary)
        insights = try container.decodeIfPresent([String].self, forKey: .insights) ?? []
        consumedAt = try container.decodeIfPresent(Date.self, forKey: .consumedAt) ?? Date()
        sourceType = try container.decodeIfPresent(MealSourceType.self, forKey: .sourceType) ?? .manual
        rawInput = try container.decodeIfPresent(String.self, forKey: .rawInput) ?? name
        detectedItems = try container.decodeIfPresent([DetectedFoodItem].self, forKey: .detectedItems) ?? []
        timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? consumedAt
        imagePreviewData = try container.decodeIfPresent(Data.self, forKey: .imagePreviewData)
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
