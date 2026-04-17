import SwiftUI

struct WorkoutPlanView: View {
    @StateObject private var manager = WorkoutsManager.shared

    var body: some View {
        List {
            if let workout = manager.todayWorkout {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(workout.title)
                            .font(.headline)
                        Text("Estimated Duration: \(workout.estimatedDurationMinutes) min")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Exercises") {
                    ForEach(workout.exercises) { exercise in
                        NavigationLink {
                            WorkoutDetailView(exercise: exercise)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.name)
                                    Text("\(exercise.sets)x\(exercise.reps) · Rest \(exercise.restSeconds)s")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: exercise.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(exercise.isCompleted ? .green : .secondary)
                            }
                        }
                    }
                }
            } else {
                ContentUnavailableView("No Workout Yet", systemImage: "figure.strengthtraining.functional", description: Text("Complete onboarding to generate an AI workout plan."))
            }
        }
        .navigationTitle("Workout Plan")
        .toolbar {
            Button("Refresh") {
                manager.generateTodayWorkoutIfNeeded(force: true)
            }
        }
    }
}
