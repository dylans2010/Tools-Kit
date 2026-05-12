import SwiftUI

struct GitHubRefactorPlannerView: View {
    @State private var refactorPlan: [RefactorStep] = []
    @State private var isAnalyzing = false

    var body: some View {
        List {
            Section {
                if isAnalyzing {
                    HStack {
                        ProgressView()
                        Text("Analyzing project structure...").font(.caption).foregroundStyle(.secondary)
                    }
                } else if refactorPlan.isEmpty {
                    Text("No refactor suggestions. Run analysis to identify candidates.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(refactorPlan) { step in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(step.title).font(.subheadline.bold())
                                Spacer()
                                Text("\(Int(step.progress * 100))%").font(.caption2).foregroundStyle(.secondary)
                            }
                            Text(step.description).font(.caption).foregroundStyle(.secondary)

                            ProgressView(value: step.progress)
                                .tint(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                Text("Refactor Roadmap")
            }

            Section {
                Button("Generate Refactor Plan") {
                    generatePlan()
                }
                .frame(maxWidth: .infinity)
                .disabled(isAnalyzing)
            }
        }
        .navigationTitle("Refactor Planner")
    }

    private func generatePlan() {
        isAnalyzing = true
        // Real logic: In a production app, this would use the RepoAnalyzerService results
        // or scan the directory for large files/complex modules.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.refactorPlan = [
                RefactorStep(title: "Decouple Security Views", description: "Move subviews from SecurityHomeView into standalone files.", progress: 0.2),
                RefactorStep(title: "Optimize GitEngine Sync", description: "Implement background persistence for staged changes.", progress: 0.5),
                RefactorStep(title: "Standardize Intelligence Cards", description: "Refactor ToolCardView into a shared component.", progress: 0.8)
            ]
            self.isAnalyzing = false
        }
    }
}

struct RefactorStep: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let description: String
    let progress: Double
}
