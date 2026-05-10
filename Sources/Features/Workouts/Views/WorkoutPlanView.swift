import SwiftUI

struct WorkoutPlanView: View {
    @StateObject private var manager = WorkoutsManager.shared
    @State private var isGenerating = false
    @State private var generationNote = ""
    @State private var errorMessage: String?

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
                    LabeledContent("Difficulty", value: workout.difficulty.capitalized)
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
                                        .foregroundStyle(exercise.isCompleted ? Color.green : Color.secondary)
                                }
                                Text("\(exercise.sets)x\(exercise.reps) • \(exercise.muscleGroup) • Rest \(exercise.restSeconds)s • ~\(exercise.durationMinutes)m")
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

            if let errorMessage {
                Section("AI Error") {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
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

        let result = await manager.generateAIWorkout(force: true)
        switch result {
        case .success:
            generationNote = "Last generated: \(Date().formatted(date: .abbreviated, time: .shortened))"
            errorMessage = nil
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}
