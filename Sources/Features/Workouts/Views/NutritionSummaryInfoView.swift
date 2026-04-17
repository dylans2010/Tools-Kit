import SwiftUI

struct NutritionSummaryInfoView: View {
    let summary: NutritionSummaryInfo

    var body: some View {
        List {
            Section {
                Label(summary.title, systemImage: "sparkles")
                LabeledContent("Calories Estimate", value: "\(summary.estimatedCalories) kcal")
                LabeledContent("Confidence", value: "\(Int(summary.confidence * 100))%")
            }

            Section("Macro quality") {
                macroRow(name: "Protein", macro: summary.protein, symbol: "bolt.heart")
                macroRow(name: "Carbs", macro: summary.carbs, symbol: "leaf")
                macroRow(name: "Fats", macro: summary.fats, symbol: "drop")
            }

            Section("Additional") {
                LabeledContent("Hydration", value: String(format: "%.1f L", summary.hydrationLiters))
                LabeledContent("Sodium", value: "\(summary.sodiumMilligrams) mg")
                LabeledContent("Fiber", value: String(format: "%.1f g", summary.fiberGrams))
                LabeledContent("Sugar", value: String(format: "%.1f g", summary.sugarGrams))
            }

            Section("Recommendations") {
                ForEach(summary.recommendations, id: \.self) { rec in
                    Label(rec, systemImage: "checkmark.seal")
                        .font(.subheadline)
                }
            }

            if !summary.detectedFoods.isEmpty {
                Section("Detected Foods") {
                    ForEach(summary.detectedFoods, id: \.self) { item in
                        Label(item.capitalized, systemImage: "fork.knife")
                    }
                }
            }
        }
        .navigationTitle("Nutrition Insights")
    }

    private func macroRow(name: String, macro: NutritionSummaryInfo.MacroRange, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(name, systemImage: symbol)
            Text("\(Int(macro.consumed))/\(Int(macro.goal))g • Quality \(Int(macro.qualityScore * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
            ProgressView(value: min(macro.consumed / max(macro.goal, 1), 1.2), total: 1.0)
        }
    }
}
