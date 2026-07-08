import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct MealDetailView: View {
    let meal: MealRecord

    var body: some View {
        List {
            Section("Overview") {
                LabeledContent("Meal", value: meal.mealType.rawValue.capitalized)
                LabeledContent("Source", value: meal.sourceType.rawValue.capitalized)
                LabeledContent("Calories", value: "\(meal.calories)")
                LabeledContent("Macros", value: "P\(Int(meal.proteinGrams)) C\(Int(meal.carbsGrams)) F\(Int(meal.fatsGrams))")
                if !meal.summary.isEmpty {
                    Text(meal.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !meal.insights.isEmpty {
                Section("Insights") {
                    ForEach(meal.insights, id: \.self) { insight in
                        Label(insight, systemImage: "lightbulb")
                    }
                }
            }

            Section("Foods") {
                ForEach(meal.detectedItems) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.subheadline.bold())
                        Text("\(item.portionDescription) • \(item.estimatedCalories) kcal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let data = meal.imagePreviewData, let image = UIImage(data: data) {
                Section("Image") {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .navigationTitle(meal.name)
    }
}
