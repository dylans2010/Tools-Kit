import SwiftUI

struct OnboardWorkoutView: View {
    @StateObject private var manager = WorkoutsManager.shared

    @State private var step = 0
    @State private var weightKg = ""
    @State private var heightCm = ""
    @State private var age = ""
    @State private var selectedGoal: UserFitnessProfile.FitnessGoal = .maintain
    @State private var selectedActivity: UserFitnessProfile.ActivityLevel = .moderatelyActive

    private let steps = ["About You", "Fitness Goal", "Activity", "Review"]

    var body: some View {
        VStack(spacing: 0) {
            header
            TabView(selection: $step) {
                profileStep.tag(0)
                goalStep.tag(1)
                activityStep.tag(2)
                reviewStep.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            controls
                .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Welcome to AI Workout Planner")
                .font(.title2.weight(.bold))
            Text("Step \(step + 1) of \(steps.count) • \(steps[step])")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ProgressView(value: Double(step + 1), total: Double(steps.count))
        }
        .padding()
    }

    private var profileStep: some View {
        Form {
            Section("Body Metrics") {
                TextField("Weight (kg)", text: $weightKg)
                    .keyboardType(.decimalPad)
                TextField("Height (cm)", text: $heightCm)
                    .keyboardType(.decimalPad)
                TextField("Age (optional)", text: $age)
                    .keyboardType(.numberPad)
            }
        }
    }

    private var goalStep: some View {
        Form {
            Section("Primary Goal") {
                Picker("Goal", selection: $selectedGoal) {
                    ForEach(UserFitnessProfile.FitnessGoal.allCases) { goal in
                        Label(goal.rawValue, systemImage: "target").tag(goal)
                    }
                }
            }
        }
    }

    private var activityStep: some View {
        Form {
            Section("Activity Level") {
                Picker("Activity", selection: $selectedActivity) {
                    ForEach(UserFitnessProfile.ActivityLevel.allCases) { level in
                        Label(level.rawValue, systemImage: "figure.run").tag(level)
                    }
                }
            }
        }
    }

    private var reviewStep: some View {
        List {
            Label("Weight: \(weightKg) kg", systemImage: "scalemass")
            Label("Height: \(heightCm) cm", systemImage: "ruler")
            Label("Age: \(age.isEmpty ? "Not set" : age)", systemImage: "person")
            Label("Goal: \(selectedGoal.rawValue)", systemImage: "target")
            Label("Activity: \(selectedActivity.rawValue)", systemImage: "figure.walk")
            Text("Your AI engine will use these details to generate personalized workouts and nutrition insights.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var controls: some View {
        HStack {
            Button("Back") {
                withAnimation { step = max(step - 1, 0) }
            }
            .disabled(step == 0)

            Spacer()

            if step < steps.count - 1 {
                Button("Next") {
                    withAnimation { step = min(step + 1, steps.count - 1) }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Finish Setup") {
                    saveProfile()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSave)
            }
        }
    }

    private var canSave: Bool {
        Double(weightKg) != nil && Double(heightCm) != nil
    }

    private func saveProfile() {
        guard let weight = Double(weightKg), let height = Double(heightCm) else { return }
        manager.saveProfile(
            UserFitnessProfile(
                weightKg: weight,
                heightCm: height,
                age: Int(age),
                goal: selectedGoal,
                activityLevel: selectedActivity
            )
        )
    }
}
