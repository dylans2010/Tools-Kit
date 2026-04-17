import SwiftUI

struct MealPlanView: View {
    @StateObject private var manager = WorkoutsManager.shared

    var body: some View {
        List {
            if let todayPlan = manager.currentMealPlan {
                Section("Today") {
                    ForEach(todayPlan.meals) { meal in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(meal.type.rawValue.capitalized): \(meal.name)")
                                .font(.subheadline.bold())
                            Text("\(meal.calories) kcal · P\(Int(meal.protein)) C\(Int(meal.carbs)) F\(Int(meal.fats))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section {
                    NavigationLink("Open Grocery List") {
                        GroceryListView(items: todayPlan.groceryItems)
                    }
                }
            } else {
                ContentUnavailableView("No Meal Plan", systemImage: "list.bullet.clipboard", description: Text("Generate your meal plan to get started."))
            }

            Section {
                Button("Generate Weekly Plan") {
                    manager.generateWeeklyMealPlans()
                }
            }
        }
        .navigationTitle("Meal Planning")
        .onAppear {
            manager.generateMealPlanIfNeeded()
        }
    }
}
