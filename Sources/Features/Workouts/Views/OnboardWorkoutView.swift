import SwiftUI

struct OnboardWorkoutView: View {
    @StateObject private var manager = WorkoutsManager.shared

    @State private var weightKg = ""
    @State private var heightCm = ""
    @State private var age = ""
    @State private var selectedGoal: UserFitnessProfile.FitnessGoal = .maintain
    @State private var selectedActivity: UserFitnessProfile.ActivityLevel = .moderatelyActive

    var body: some View {
        Form {
            Section("Profile") {
                TextField("Weight (kg)", text: $weightKg)
                    .keyboardType(.decimalPad)
                TextField("Height (cm)", text: $heightCm)
                    .keyboardType(.decimalPad)
                TextField("Age (optional)", text: $age)
                    .keyboardType(.numberPad)
            }

            Section("Fitness Goal") {
                Picker("Goal", selection: $selectedGoal) {
                    ForEach(UserFitnessProfile.FitnessGoal.allCases) { goal in
                        Text(goal.rawValue).tag(goal)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section("Activity Level") {
                Picker("Activity", selection: $selectedActivity) {
                    ForEach(UserFitnessProfile.ActivityLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Button("Save Profile") {
                saveProfile()
            }
            .disabled(!canSave)
        }
        .navigationTitle("Workout Onboarding")
    }

    private var canSave: Bool {
        Double(weightKg) != nil && Double(heightCm) != nil
    }

    private func saveProfile() {
        guard let weight = Double(weightKg),
              let height = Double(heightCm) else { return }

        let userAge = Int(age)
        let profile = UserFitnessProfile(
            weightKg: weight,
            heightCm: height,
            age: userAge,
            goal: selectedGoal,
            activityLevel: selectedActivity
        )
        manager.saveProfile(profile)
    }
}
