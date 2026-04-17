import SwiftUI
import Charts

struct ProgressView: View {
    @StateObject private var manager = WorkoutsManager.shared

    var body: some View {
        List {
            if !manager.progress.isEmpty {
                Section("Weight") {
                    Chart(manager.progress) { item in
                        if let weight = item.weightKg {
                            LineMark(
                                x: .value("Date", item.date),
                                y: .value("Weight", weight)
                            )
                            .foregroundStyle(.blue)
                        }
                    }
                    .frame(height: 180)
                }

                Section("Workout Consistency") {
                    Chart(manager.progress) { item in
                        BarMark(
                            x: .value("Date", item.date),
                            y: .value("Workouts", item.workoutsCompleted)
                        )
                        .foregroundStyle(.green)
                    }
                    .frame(height: 180)
                }

                Section("Calories Burned") {
                    Chart(manager.progress) { item in
                        AreaMark(
                            x: .value("Date", item.date),
                            y: .value("Calories", item.caloriesBurned)
                        )
                        .foregroundStyle(.orange.opacity(0.7))
                    }
                    .frame(height: 180)
                }
            } else {
                ContentUnavailableView("No Progress Yet", systemImage: "chart.xyaxis.line")
            }
        }
        .navigationTitle("Progress")
    }
}
