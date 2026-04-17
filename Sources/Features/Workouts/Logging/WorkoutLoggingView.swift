import SwiftUI

struct WorkoutLoggingView: View {
    @StateObject private var manager = WorkoutsManager.shared
    @State private var draftTitle: String = ""
    @State private var fatigue: Int = 3
    @State private var notes: String = ""
    @State private var logs: [ExerciseSessionLog] = []

    var body: some View {
        Form {
            Section("Session") {
                TextField("Workout title", text: $draftTitle)
                Stepper("Fatigue: \(fatigue)/5", value: $fatigue, in: 1...5)
                TextField("Notes", text: $notes, axis: .vertical)
            }

            ForEach($logs) { $log in
                ExerciseLoggingView(log: $log)
            }

            Button("Save Session") {
                manager.saveWorkoutSession(
                    title: draftTitle.isEmpty ? (manager.todayWorkout?.title ?? "Workout Session") : draftTitle,
                    fatigueLevel: fatigue,
                    logs: logs,
                    notes: notes
                )
                resetDraft()
            }
            .buttonStyle(.borderedProminent)
            .disabled(logs.isEmpty)
        }
        .navigationTitle("Workout Logging")
        .onAppear(perform: seedDraft)
    }

    private func seedDraft() {
        if !logs.isEmpty { return }
        draftTitle = manager.todayWorkout?.title ?? "Workout Session"
        logs = (manager.todayWorkout?.exercises ?? []).map { exercise in
            ExerciseSessionLog(
                exerciseName: exercise.name,
                durationMinutes: exercise.durationMinutes,
                sets: (1...max(exercise.sets, 1)).map { setNumber in
                    ExerciseSetLog(setNumber: setNumber, reps: max(exercise.reps, 1), weightKg: 0)
                }
            )
        }
    }

    private func resetDraft() {
        fatigue = 3
        notes = ""
        logs = []
        seedDraft()
    }
}
