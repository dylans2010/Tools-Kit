import SwiftUI

struct GitHubRefactorPlannerView: View {
    @State private var refactorPlan: [RefactorStep] = [
        RefactorStep(title: "Extract Network Layer", description: "Modularize GitHubAPIClient and AuthManager.", progress: 0.3),
        RefactorStep(title: "SwiftUI Migration", description: "Convert remaining UIKit RepoList to SwiftUI.", progress: 0.9),
        RefactorStep(title: "Dependency Injection", description: "Implement DI container for shared services.", progress: 0.0)
    ]

    var body: some View {
        List {
            Section("Refactor Roadmap") {
                ForEach(refactorPlan) { step in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(step.title).font(.subheadline.bold())
                            Spacer()
                            Text("\(Int(step.progress * 100))%").font(.caption2).foregroundStyle(.secondary)
                        }
                        Text(step.description).font(.caption).foregroundStyle(.secondary)

                        ProgressView(value: step.progress)
                            .tint(.purple)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Dependency Analysis") {
                Label("Detected 3 Circular Dependencies", systemImage: "arrow.triangle.2.circlepath").foregroundStyle(.red)
                Label("Identify Refactor Candidates", systemImage: "lightbulb.fill").foregroundStyle(.yellow)
            }
        }
        .navigationTitle("Refactor Planner")
    }
}

struct RefactorStep: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let progress: Double
}
