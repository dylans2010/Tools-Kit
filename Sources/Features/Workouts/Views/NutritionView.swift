import SwiftUI

struct NutritionView: View {
    @StateObject private var manager = WorkoutsManager.shared

    @State private var manualInput: String = ""
    @State private var manualName: String = ""

    var body: some View {
        List {
            Section("Daily Summary") {
                LabeledContent("Calories Consumed", value: "\(manager.nutrition.caloriesConsumed)")
                LabeledContent("Remaining Calories", value: "\(manager.nutrition.remainingCalories)")
                LabeledContent("Protein", value: "\(Int(manager.nutrition.proteinConsumed))/\(Int(manager.nutrition.proteinGoal)) g")
                LabeledContent("Carbs", value: "\(Int(manager.nutrition.carbsConsumed))/\(Int(manager.nutrition.carbsGoal)) g")
                LabeledContent("Fats", value: "\(Int(manager.nutrition.fatsConsumed))/\(Int(manager.nutrition.fatsGoal)) g")
            }

            Section("Meal Logging") {
                NavigationLink("Scan Meal") { MealScannerView() }
                NavigationLink("Voice Log") { MealVoiceLoggingView() }
            }

            Section("Manual Meal") {
                TextField("Meal name", text: $manualName)
                TextField("Describe meal", text: $manualInput, axis: .vertical)
                Button("Add Manual Meal") {
                    let input = manualInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !input.isEmpty else { return }
                    let analysis = manager.analyzeMealInput(input, sourceType: .manual, imageData: nil)
                    manager.addMeal(
                        name: manualName.isEmpty ? "Manual Meal" : manualName,
                        analysis: analysis,
                        sourceType: .manual,
                        rawInput: input
                    )
                    manualInput = ""
                    manualName = ""
                }
                .buttonStyle(.borderedProminent)
                .disabled(manualInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Section("Meals") {
                if manager.nutrition.meals.isEmpty {
                    Text("No meals logged yet.")
                        .foregroundColor(.secondary)
                }

                ForEach(manager.nutrition.meals) { meal in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(meal.name)
                                .font(.subheadline.bold())
                            Spacer()
                            Text(meal.sourceType.rawValue.capitalized)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        Text("\(meal.calories) cal · P\(Int(meal.proteinGrams)) C\(Int(meal.carbsGrams)) F\(Int(meal.fatsGrams))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if !meal.detectedItems.isEmpty {
                            Text(meal.detectedItems.map(\.name).joined(separator: ", "))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Nutrition")
    }
}
