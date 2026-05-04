import SwiftUI

struct RepoDetailView_Developer: View {
    let repo: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Developer Tools")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink(destination: CodeAssistantView()) {
                    DevToolCard(title: "AI Assistant", icon: "sparkles", color: .purple)
                }
                NavigationLink(destination: RepoTasksView(repo: repo)) {
                    DevToolCard(title: "Repo Tasks", icon: "checklist", color: .blue)
                }
                NavigationLink(destination: DevWorkflowView()) {
                    DevToolCard(title: "CI/CD Sync", icon: "arrow.triangle.2.circlepath", color: .green)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct DevToolCard: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(title)
                .font(.caption.bold())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}
