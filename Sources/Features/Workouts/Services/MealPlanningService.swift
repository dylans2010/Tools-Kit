import Foundation

final class MealPlanningService {
    func generatePlan(for date: Date, nutrition: NutritionModel, profile: UserFitnessProfile?) -> MealPlanModel {
        let baseCalories = max(nutrition.calorieGoal, 1400)
        let breakfast = MealPlanItem(
            name: "Protein Oats Bowl",
            type: .breakfast,
            calories: Int(Double(baseCalories) * 0.25),
            protein: nutrition.proteinGoal * 0.25,
            carbs: nutrition.carbsGoal * 0.30,
            fats: nutrition.fatsGoal * 0.20,
            ingredients: ["oats", "greek yogurt", "berries", "chia seeds"]
        )
        let lunch = MealPlanItem(
            name: "Chicken Rice Veggie Bowl",
            type: .lunch,
            calories: Int(Double(baseCalories) * 0.33),
            protein: nutrition.proteinGoal * 0.35,
            carbs: nutrition.carbsGoal * 0.35,
            fats: nutrition.fatsGoal * 0.30,
            ingredients: ["chicken", "rice", "broccoli", "olive oil"]
        )
        let dinner = MealPlanItem(
            name: "Salmon Sweet Potato Plate",
            type: .dinner,
            calories: Int(Double(baseCalories) * 0.30),
            protein: nutrition.proteinGoal * 0.30,
            carbs: nutrition.carbsGoal * 0.25,
            fats: nutrition.fatsGoal * 0.35,
            ingredients: ["salmon", "sweet potato", "spinach", "lemon"]
        )
        let snack = MealPlanItem(
            name: "Protein Snack",
            type: .snack,
            calories: Int(Double(baseCalories) * 0.12),
            protein: nutrition.proteinGoal * 0.10,
            carbs: nutrition.carbsGoal * 0.10,
            fats: nutrition.fatsGoal * 0.15,
            ingredients: ["protein shake", "banana", "almonds"]
        )

        let profileGoal = profile?.goal.rawValue ?? "Maintain"
        return MealPlanModel(
            date: date,
            meals: [breakfast, lunch, dinner, snack],
            notes: "Auto-generated for goal: \(profileGoal)."
        )
    }

    func generateWeeklyPlan(startingAt date: Date, nutrition: NutritionModel, profile: UserFitnessProfile?) -> [MealPlanModel] {
        let calendar = Calendar.current
        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: date) else { return nil }
            return generatePlan(for: day, nutrition: nutrition, profile: profile)
        }
    }
}
