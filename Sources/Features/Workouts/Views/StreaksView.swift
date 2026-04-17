import SwiftUI

struct StreaksView: View {
    @StateObject private var manager = WorkoutsManager.shared

    var body: some View {
        List {
            Section("Workout Streak") {
                LabeledContent("Current", value: "\(manager.streak.currentDays) days")
                LabeledContent("Longest", value: "\(manager.streak.longestDays) days")
                if let last = manager.streak.lastWorkoutDate {
                    LabeledContent("Last Workout", value: last.formatted(date: .abbreviated, time: .omitted))
                }
            }
        }
        .navigationTitle("Streaks")
    }
}
