import SwiftUI

struct GitHubProjectKanbanView: View {
    let owner: String
    let repo: String

    @State private var todoIssues: [GitHubIssue] = []
    @State private var inProgressIssues: [GitHubIssue] = []
    @State private var doneIssues: [GitHubIssue] = []
    @State private var isLoading = false

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 20) {
                KanbanColumn(title: "To Do", issues: todoIssues, color: .secondary)
                KanbanColumn(title: "In Progress", issues: inProgressIssues, color: .blue)
                KanbanColumn(title: "Done", issues: doneIssues, color: .green)
            }
            .padding()
        }
        .navigationTitle("Project Board")
        .background(Color(.systemGroupedBackground))
        .task {
            await fetchIssues()
        }
    }

    private func fetchIssues() async {
        isLoading = true
        do {
            let issues: [GitHubIssue] = try await GitHubAPIClient.shared.request(.repoIssues(owner: owner, repo: repo))
            await MainActor.run {
                self.todoIssues = issues.filter { $0.state == .open && $0.labels.isEmpty }
                self.inProgressIssues = issues.filter { $0.state == .open && !$0.labels.isEmpty }
                self.doneIssues = issues.filter { $0.state == .closed }
                self.isLoading = false
            }
        } catch {
            print("Failed to fetch issues: \(error)")
            isLoading = false
        }
    }
}

private struct KanbanColumn: View {
    let title: String
    let issues: [GitHubIssue]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(title).font(.headline)
                Spacer()
                Text("\(issues.count)").font(.caption.bold()).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

            ScrollView {
                VStack(spacing: 10) {
                    if issues.isEmpty {
                        Text("No items").font(.caption).foregroundStyle(.secondary).padding()
                    } else {
                        ForEach(issues) { issue in
                            KanbanCard(issue: issue)
                        }
                    }
                }
            }
        }
        .frame(width: 280)
    }
}

private struct KanbanCard: View {
    let issue: GitHubIssue

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(issue.title)
                .font(.subheadline.bold())
                .lineLimit(2)

            HStack {
                Text("#\(issue.number)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}
