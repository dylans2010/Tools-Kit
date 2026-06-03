import SwiftUI

struct DeveloperOnboardingView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared

    var body: some View {
        List {
            Section("Your Onboarding Progress") {
                VStack(alignment: .leading, spacing: 16) {
                    let steps = store.onboardingSteps
                    ProgressView(value: steps.isEmpty ? 0 : Double(steps.filter { $0.isCompleted }.count) / Double(steps.count))
                        .tint(.green)

                    Text("\(steps.filter { $0.isCompleted }.count) of \(steps.count) tasks complete")
                        .font(.caption.bold())
                }
                .padding(.vertical, 8)
            }

            Section("Required Tasks") {
                ForEach(store.onboardingSteps) { step in
                    HStack {
                        Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(step.isCompleted ? .green : .secondary)
                        Text(step.title)
                        Spacer()
                        if !step.isCompleted {
                            Button("Start") {
                                var current = store.onboardingSteps
                                if let idx = current.firstIndex(where: { $0.id == step.id }) {
                                    current[idx].isCompleted = true
                                    store.saveOnboardingSteps(current)
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }
        }
        .navigationTitle("Onboarding")
        .onAppear {
            if store.onboardingSteps.isEmpty {
                store.saveOnboardingSteps([
                    OnboardingStep(title: "Accept Terms of Service", isCompleted: true),
                    OnboardingStep(title: "Verify Identity", isCompleted: false),
                    OnboardingStep(title: "Setup Two-Factor Auth", isCompleted: false),
                    OnboardingStep(title: "Create First Project", isCompleted: false)
                ])
            }
        }
    }
}
