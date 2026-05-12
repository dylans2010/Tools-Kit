import Foundation

enum MealType: String, Codable, CaseIterable, Identifiable, Sendable {
    case breakfast
    case lunch
    case dinner
    case snack

    var id: String { rawValue }
}

struct MealPlanItem: Identifiable, Codable, Sendable {
    var id: UUID
    var name: String
    var type: MealType
    var calories: Int
    var protein: Double
    var carbs: Double
    var fats: Double
    var ingredients: [String]

    init(
        id: UUID = UUID(),
        name: String,
        type: MealType,
        calories: Int,
        protein: Double,
        carbs: Double,
        fats: Double,
        ingredients: [String]
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.ingredients = ingredients
    }
}

struct MealPlanModel: Identifiable, Codable, Sendable {
    var id: UUID
    var date: Date
    var meals: [MealPlanItem]
    var notes: String

    init(id: UUID = UUID(), date: Date = Date(), meals: [MealPlanItem], notes: String = "") {
        self.id = id
        self.date = date
        self.meals = meals
        self.notes = notes
    }

    var groceryItems: [String] {
        Array(Set(meals.flatMap(\.ingredients))).sorted()
    }
}
