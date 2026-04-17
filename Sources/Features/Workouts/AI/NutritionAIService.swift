import Foundation

struct MealAnalysis {
    var calories: Int
    var proteinGrams: Double
    var carbsGrams: Double
    var fatsGrams: Double
    var summary: String
    var detectedItems: [DetectedFoodItem]
    var cleanedInput: String
}

final class NutritionAIService {
    func analyzeMeal(rawInput: String, sourceType: MealSourceType, imageData: Data?, profile: UserFitnessProfile?) -> MealAnalysis {
        let cleanedInput = cleanInput(rawInput)

        var detectedItems = detectItemsFromText(cleanedInput)
        if sourceType == .image || imageData != nil {
            detectedItems = mergeWithImageDetection(items: detectedItems, imageData: imageData)
        }

        if detectedItems.isEmpty {
            detectedItems = [
                DetectedFoodItem(name: cleanedInput.isEmpty ? "Mixed meal" : cleanedInput, category: .mixed, portionDescription: "1 serving", estimatedCalories: 350)
            ]
        }

        let macros = macroEstimate(from: detectedItems, activityBoost: profile?.activityLevel.multiplier ?? 1.0)
        return MealAnalysis(
            calories: macros.calories,
            proteinGrams: macros.protein,
            carbsGrams: macros.carbs,
            fatsGrams: macros.fats,
            summary: summary(for: detectedItems, sourceType: sourceType),
            detectedItems: detectedItems,
            cleanedInput: cleanedInput
        )
    }

    func recalculate(from items: [DetectedFoodItem], profile: UserFitnessProfile?) -> MealAnalysis {
        let macros = macroEstimate(from: items, activityBoost: profile?.activityLevel.multiplier ?? 1.0)
        return MealAnalysis(
            calories: macros.calories,
            proteinGrams: macros.protein,
            carbsGrams: macros.carbs,
            fatsGrams: macros.fats,
            summary: "Adjusted from edited items.",
            detectedItems: items,
            cleanedInput: items.map(\.name).joined(separator: ", ")
        )
    }

    func cleanInput(_ input: String) -> String {
        let lowered = input.lowercased()
            .replacingOccurrences(of: "i had", with: "")
            .replacingOccurrences(of: "for lunch", with: "")
            .replacingOccurrences(of: "for dinner", with: "")
            .replacingOccurrences(of: "for breakfast", with: "")
            .replacingOccurrences(of: "and", with: ",")
        let tokens = lowered
            .components(separatedBy: CharacterSet(charactersIn: ",."))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return tokens.joined(separator: ", ")
    }

    func recommendedTargets(for profile: UserFitnessProfile) -> (calories: Int, protein: Double, carbs: Double, fats: Double) {
        let age = Double(profile.age ?? 30)
        let bmr = 10 * profile.weightKg + 6.25 * profile.heightCm - 5 * age + 5
        var calories = Int(bmr * profile.activityLevel.multiplier)

        switch profile.goal {
        case .gainMuscle, .gainWeight:
            calories += 250
        case .loseWeight:
            calories -= 350
        case .maintain:
            break
        }

        let protein = profile.weightKg * 1.8
        let fats = profile.weightKg * 0.8
        let carbs = max((Double(calories) - ((protein * 4) + (fats * 9))) / 4, 80)

        return (max(calories, 1400), protein, carbs, fats)
    }

    private func detectItemsFromText(_ text: String) -> [DetectedFoodItem] {
        let fragments = text
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return fragments.map { fragment in
            let category = categorize(fragment)
            return DetectedFoodItem(
                name: fragment,
                category: category,
                portionDescription: inferredPortion(for: fragment),
                estimatedCalories: calories(for: category, portion: inferredPortion(for: fragment))
            )
        }
    }

    private func mergeWithImageDetection(items: [DetectedFoodItem], imageData: Data?) -> [DetectedFoodItem] {
        var merged = items
        guard let imageData, !imageData.isEmpty else { return merged }

        let defaults: [DetectedFoodItem] = [
            DetectedFoodItem(name: "grilled protein", category: .protein, portionDescription: "palm-size", estimatedCalories: 220),
            DetectedFoodItem(name: "rice or grains", category: .carbs, portionDescription: "1 cup", estimatedCalories: 210),
            DetectedFoodItem(name: "mixed vegetables", category: .vegetables, portionDescription: "1 cup", estimatedCalories: 80),
            DetectedFoodItem(name: "hydration drink", category: .drinks, portionDescription: "1 glass", estimatedCalories: 20)
        ]

        for fallback in defaults {
            if !merged.contains(where: { $0.category == fallback.category }) {
                merged.append(fallback)
            }
        }

        return merged
    }

    private func categorize(_ fragment: String) -> FoodCategory {
        let proteins = ["chicken", "beef", "fish", "salmon", "egg", "tofu", "turkey", "protein"]
        let carbs = ["rice", "bread", "pasta", "potato", "oats", "noodle", "cereal"]
        let vegetables = ["broccoli", "spinach", "salad", "vegetable", "carrot", "pepper", "cucumber"]
        let drinks = ["water", "juice", "coffee", "tea", "smoothie", "milk", "soda"]
        let fats = ["avocado", "nuts", "olive oil", "butter", "peanut"]

        if proteins.contains(where: fragment.contains) { return .protein }
        if carbs.contains(where: fragment.contains) { return .carbs }
        if vegetables.contains(where: fragment.contains) { return .vegetables }
        if drinks.contains(where: fragment.contains) { return .drinks }
        if fats.contains(where: fragment.contains) { return .fats }
        return .mixed
    }

    private func inferredPortion(for fragment: String) -> String {
        if fragment.contains("cup") { return "1 cup" }
        if fragment.contains("slice") { return "2 slices" }
        if fragment.contains("bowl") { return "1 bowl" }
        if fragment.contains("glass") { return "1 glass" }
        return "1 serving"
    }

    private func calories(for category: FoodCategory, portion: String) -> Int {
        let multiplier: Double
        if portion.contains("2") { multiplier = 1.4 }
        else if portion.contains("bowl") { multiplier = 1.3 }
        else { multiplier = 1.0 }

        let base: Int
        switch category {
        case .protein: base = 220
        case .carbs: base = 210
        case .vegetables: base = 70
        case .drinks: base = 90
        case .fats: base = 150
        case .mixed: base = 180
        }

        return Int(Double(base) * multiplier)
    }

    private func macroEstimate(from items: [DetectedFoodItem], activityBoost: Double) -> (calories: Int, protein: Double, carbs: Double, fats: Double) {
        var calories = 0
        var protein = 0.0
        var carbs = 0.0
        var fats = 0.0

        for item in items {
            calories += item.estimatedCalories
            switch item.category {
            case .protein:
                protein += 26
                fats += 8
            case .carbs:
                carbs += 35
                protein += 4
            case .vegetables:
                carbs += 10
                protein += 3
            case .drinks:
                carbs += 18
            case .fats:
                fats += 15
            case .mixed:
                protein += 10
                carbs += 18
                fats += 8
            }
        }

        let adjusted = min(max(activityBoost, 1.0), 1.6)
        return (
            max(Int(Double(calories) * adjusted), 120),
            protein * adjusted,
            carbs * adjusted,
            fats * adjusted
        )
    }

    private func summary(for items: [DetectedFoodItem], sourceType: MealSourceType) -> String {
        let categories = Set(items.map(\.category.rawValue))
        return "\(sourceType.rawValue.capitalized) analysis detected \(items.count) item(s): \(categories.sorted().joined(separator: ", "))."
    }
}
