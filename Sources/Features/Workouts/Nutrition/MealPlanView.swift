import SwiftUI

struct MealPlanView: View {
    @StateObject private var manager = WorkoutsManager.shared

    var body: some View {
        List {
            if let todayPlan = manager.currentMealPlan {
                Section("Today's Personalized Meals") {
                    ForEach(todayPlan.meals) { meal in
                        VStack(alignment: .leading, spacing: 4) {
                            Label("\(meal.type.rawValue.capitalized): \(meal.name)", systemImage: "fork.knife")
                                .font(.subheadline.bold())
                            Text("\(meal.calories) kcal · P\(Int(meal.protein)) C\(Int(meal.carbs)) F\(Int(meal.fats))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section {
                    NavigationLink {
                        GroceryListView(items: todayPlan.groceryItems)
                    } label: {
                        Label("Open Grocery List", systemImage: "cart.fill")
                    }
                }
            } else {
                ContentUnavailableView("No Meal Plan", systemImage: "list.bullet.clipboard", description: Text("Generate a plan to get started."))
            }

            Section("AI Planning") {
                Button {
                    manager.generateMealPlanIfNeeded(force: true)
                } label: {
                    Label("Generate Today's Plan", systemImage: "sparkles")
                }

                Button {
                    manager.generateWeeklyMealPlans()
                } label: {
                    Label("Generate Weekly Plan", systemImage: "calendar")
                }
            }
        }
        .navigationTitle("Meal Planning")
        .onAppear { manager.generateMealPlanIfNeeded() }
    }
}
