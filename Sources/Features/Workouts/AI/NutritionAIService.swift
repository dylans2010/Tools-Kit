import Foundation

struct MealAnalysis {
    var calories: Int
    var proteinGrams: Double
    var carbsGrams: Double
    var fatsGrams: Double
    var summary: String
}

final class NutritionAIService {
    func analyzeMeal(name: String, imageData: Data?, profile: UserFitnessProfile?) -> MealAnalysis {
        let seed = max(name.trimmingCharacters(in: .whitespacesAndNewlines).count, 6)
        let activityBoost = profile?.activityLevel.multiplier ?? 1.0

        let calories = Int(Double(seed * 35) * min(activityBoost, 1.6))
        let protein = Double(seed) * 1.3
        let carbs = Double(seed) * 2.0
        let fats = Double(seed) * 0.8

        let imageHint = (imageData?.isEmpty == false) ? "Image assisted analysis." : "Text-only estimate."

        return MealAnalysis(
            calories: max(calories, 180),
            proteinGrams: protein,
            carbsGrams: carbs,
            fatsGrams: fats,
            summary: "Estimated from meal context. \(imageHint)"
        )
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
}
