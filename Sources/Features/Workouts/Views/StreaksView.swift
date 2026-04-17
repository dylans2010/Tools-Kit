import SwiftUI

struct StreaksView: View {
    @StateObject private var manager = WorkoutsManager.shared

    var body: some View {
        List {
            Section("Workout Streak") {
                LabeledContent("Current", value: "\(manager.streak.currentDays) days")
                LabeledContent("Longest", value: "\(manager.streak.longestDays) days")
                LabeledContent("7-Day Completion", value: "\(Int(manager.streak.dailyCompletionRateLast7 * 100))%")
                if let last = manager.streak.lastWorkoutDate {
                    LabeledContent("Last Workout", value: last.formatted(date: .abbreviated, time: .omitted))
                }
            }

            Section("Reminders") {
                Toggle("Workout reminders", isOn: Binding(
                    get: { manager.streak.workoutReminderEnabled },
                    set: { manager.updateWorkoutReminder($0) }
                ))
            }
        }
        .navigationTitle("Streaks")
    }
}
