import SwiftUI

struct HealthDataView: View {
    @StateObject private var manager = WorkoutsManager.shared

    var body: some View {
        List {
            Section("Imported Apple Health Data") {
                LabeledContent("Steps", value: "\(manager.healthData.steps)")
                LabeledContent("Calories Burned", value: "\(Int(manager.healthData.caloriesBurned))")
                LabeledContent("Workouts", value: "\(manager.healthData.workouts)")

                if let weight = manager.healthData.latestWeightKg {
                    LabeledContent("Latest Weight", value: "\(String(format: "%.1f", weight)) kg")
                }

                if let heartRate = manager.healthData.averageHeartRate {
                    LabeledContent("Avg Heart Rate", value: "\(Int(heartRate)) bpm")
                }

                LabeledContent("Last Sync", value: manager.healthData.importedAt.formatted(date: .abbreviated, time: .shortened))
            }
        }
        .navigationTitle("Health Data")
        .toolbar {
            Button("Sync") {
                Task { await manager.syncHealthData() }
            }
        }
    }
}
