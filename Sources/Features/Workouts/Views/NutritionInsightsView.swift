import SwiftUI

struct NutritionInsightsView: View {
    let insights: NutritionInsightsModel

    var body: some View {
        List {
            Section("Summary") {
                Text(insights.summary)
                    .font(.subheadline)
            }

            Section("Totals") {
                LabeledContent("Calories", value: "\(insights.totals.calories)")
                LabeledContent("Protein", value: "\(insights.totals.protein) g")
                LabeledContent("Carbs", value: "\(insights.totals.carbs) g")
                LabeledContent("Fats", value: "\(insights.totals.fats) g")
            }

            if !insights.insights.isEmpty {
                Section("Insights") {
                    ForEach(insights.insights, id: \.self) { item in
                        Label(item, systemImage: "lightbulb")
                            .font(.subheadline)
                    }
                }
            }

            if !insights.recommendations.isEmpty {
                Section("Recommendations") {
                    ForEach(insights.recommendations, id: \.self) { item in
                        Label(item, systemImage: "checkmark.seal")
                            .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle("Nutrition Insights")
    }
}
