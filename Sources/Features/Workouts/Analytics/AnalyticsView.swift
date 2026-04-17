import SwiftUI
import Charts

struct AnalyticsView: View {
    @StateObject private var manager = WorkoutsManager.shared
    private let analyticsService = AnalyticsService()

    var body: some View {
        let summary = analyticsService.buildSummary(progress: manager.progress, performances: manager.performance)

        List {
            if !summary.weightTrend.isEmpty {
                Section("Weight Trend") {
                    Chart(summary.weightTrend) { item in
                        if let weight = item.weightKg {
                            LineMark(x: .value("Date", item.date), y: .value("Weight", weight))
                                .foregroundStyle(.blue)
                        }
                    }
                    .frame(height: 180)
                }

                Section("Consistency") {
                    Chart(summary.consistencyTrend) { item in
                        BarMark(x: .value("Date", item.date), y: .value("Workouts", item.workoutsCompleted))
                            .foregroundStyle(.green)
                    }
                    .frame(height: 180)
                }
            }

            if !summary.strengthTrend.isEmpty {
                Section("Strength Progression") {
                    Chart(summary.strengthTrend) { item in
                        LineMark(x: .value("Date", item.date), y: .value("Strength", item.strengthScore))
                            .foregroundStyle(.orange)
                    }
                    .frame(height: 180)
                }
            }

            Section("AI Insights") {
                ForEach(summary.insights, id: \.self) { insight in
                    Text(insight)
                }
            }
        }
        .navigationTitle("Analytics")
    }
}
