import SwiftUI

struct WorkoutPlanView: View {
    @StateObject private var manager = WorkoutsManager.shared
    @State private var isGenerating = false
    @State private var generationNote = ""

    private let planner = AIWorkoutPlanner()

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("AI Workout Planner", systemImage: "brain.head.profile")
                        .font(.headline)
                    Text("Generates adaptive plans using profile, performance, streaks, and nutrition consistency.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !generationNote.isEmpty {
                        Text(generationNote)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let workout = manager.todayWorkout {
                Section("Today") {
                    Label(workout.title, systemImage: "figure.strengthtraining.traditional")
                    LabeledContent("Duration", value: "\(workout.estimatedDurationMinutes) min")
                    LabeledContent("Completion", value: "\(Int(workout.completionRate * 100))%")
                }

                Section("Exercises") {
                    ForEach(workout.exercises) { exercise in
                        NavigationLink {
                            WorkoutDetailView(exercise: exercise)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Label(exercise.name, systemImage: "figure.mixed.cardio")
                                    Spacer()
                                    Image(systemName: exercise.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(exercise.isCompleted ? .green : .secondary)
                                }
                                Text("\(exercise.sets)x\(exercise.reps) • Rest \(exercise.restSeconds)s • ~\(exercise.durationMinutes)m")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if !workout.notes.isEmpty {
                    Section("AI Notes") {
                        Text(workout.notes)
                            .font(.subheadline)
                    }
                }
            } else {
                ContentUnavailableView("No Workout Yet", systemImage: "figure.strengthtraining.functional", description: Text("Complete onboarding and run the AI planner."))
            }
        }
        .overlay {
            if isGenerating {
                ProgressView("Generating your personalized plan...")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .navigationTitle("Workout Plan")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await regenerateFromAI() }
                } label: {
                    Label("Generate", systemImage: "sparkles")
                }
                .disabled(isGenerating)
            }
        }
    }

    @MainActor
    private func regenerateFromAI() async {
        guard let profile = manager.profile else { return }
        isGenerating = true
        defer { isGenerating = false }

        let userPlan = await planner.generatePlan(
            profile: profile,
            progress: manager.progress,
            streak: manager.streak,
            nutrition: manager.nutrition,
            previousWorkout: manager.todayWorkout
        )

        manager.todayWorkout = userPlan.workoutModel
        generationNote = "Last generated: \(Date().formatted(date: .abbreviated, time: .shortened))"
    }
}
