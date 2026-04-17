import SwiftUI
import Charts

struct WorkoutProgressDashboardView: View {
    @StateObject private var manager = WorkoutsManager.shared
    private let analyticsService = AnalyticsService()

    var body: some View {
        let summary = analyticsService.buildSummary(progress: manager.progress, performances: manager.performance)

        List {
            if !manager.progress.isEmpty {
                Section("Weight") {
                    Chart(manager.progress) { item in
                        if let weight = item.weightKg {
                            LineMark(x: .value("Date", item.date), y: .value("Weight", weight))
                                .foregroundStyle(.blue)
                        }
                    }
                    .frame(height: 180)
                }

                Section("Workout Consistency") {
                    Chart(manager.progress) { item in
                        BarMark(x: .value("Date", item.date), y: .value("Workouts", item.workoutsCompleted))
                            .foregroundStyle(.green)
                    }
                    .frame(height: 180)
                }

                Section("Calories Burned") {
                    Chart(manager.progress) { item in
                        AreaMark(x: .value("Date", item.date), y: .value("Calories", item.caloriesBurned))
                            .foregroundStyle(.orange.opacity(0.7))
                    }
                    .frame(height: 180)
                }

                Section("AI Insights") {
                    ForEach(summary.insights, id: \.self) { insight in
                        Text(insight)
                    }
                }

                Section {
                    NavigationLink("Open Advanced Analytics") {
                        AnalyticsView()
                    }
                }
            } else {
                ContentUnavailableView("No Progress Yet", systemImage: "chart.xyaxis.line", description: Text("Track your workout progress over time."))
            }
        }
        .navigationTitle("Progress")
    }
}
