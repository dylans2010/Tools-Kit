import SwiftUI

struct NutritionView: View {
    @StateObject private var manager = WorkoutsManager.shared

    var body: some View {
        List {
            Section("Daily Summary") {
                LabeledContent("Calories Consumed", value: "\(manager.nutrition.caloriesConsumed)")
                LabeledContent("Remaining Calories", value: "\(manager.nutrition.remainingCalories)")
                LabeledContent("Protein", value: "\(Int(manager.nutrition.proteinConsumed))/\(Int(manager.nutrition.proteinGoal)) g")
                LabeledContent("Carbs", value: "\(Int(manager.nutrition.carbsConsumed))/\(Int(manager.nutrition.carbsGoal)) g")
                LabeledContent("Fats", value: "\(Int(manager.nutrition.fatsConsumed))/\(Int(manager.nutrition.fatsGoal)) g")
            }

            Section("Meals") {
                if manager.nutrition.meals.isEmpty {
                    Text("No meals logged yet.")
                        .foregroundColor(.secondary)
                }

                ForEach(manager.nutrition.meals) { meal in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meal.name)
                            .font(.subheadline.bold())
                        Text("\(meal.calories) cal · P\(Int(meal.proteinGrams)) C\(Int(meal.carbsGrams)) F\(Int(meal.fatsGrams))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section {
                NavigationLink("Scan Meal") {
                    MealScannerView()
                }
            }
        }
        .navigationTitle("Nutrition")
    }
}
