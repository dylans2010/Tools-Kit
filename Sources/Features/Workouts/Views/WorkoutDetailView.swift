import SwiftUI

struct WorkoutDetailView: View {
    @StateObject private var manager = WorkoutsManager.shared
    let exercise: ExerciseModel

    var body: some View {
        List {
            Section("Exercise") {
                LabeledContent("Name", value: exercise.name)
                LabeledContent("Sets", value: "\(exercise.sets)")
                LabeledContent("Reps", value: "\(exercise.reps)")
                LabeledContent("Duration", value: "\(exercise.durationMinutes) min")
                if !exercise.muscleGroup.isEmpty {
                    LabeledContent("Muscle Group", value: exercise.muscleGroup)
                }
                LabeledContent("Rest", value: "\(exercise.restSeconds) sec")
            }

            Section {
                Button(exercise.isCompleted ? "Mark Incomplete" : "Mark Complete") {
                    manager.toggleExercise(exercise)
                }
            }
        }
        .navigationTitle(exercise.name)
    }
}
