import SwiftUI

struct PullRequestHubView: View {
    let spaceID: UUID
    @State private var title = ""
    @State private var reviewers = ""
    @State private var prs: [WorkspacePullRequest] = []

    var body: some View {
        List {
            Section("Create") {
                TextField("PR Title", text: $title)
                TextField("Reviewers (comma-separated)", text: $reviewers)
                Button("Create Pull Request") {
                    let pr = PullRequestService.shared.create(spaceID: spaceID, title: title, sourceBranch: "feature", targetBranch: "main", reviewers: reviewers.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }, requiredApprovals: 1)
                    prs.insert(pr, at: 0)
                    title = ""
                }
                .disabled(title.isEmpty)
            }
            Section("Open Pull Requests") {
                ForEach(prs) { pr in
                    VStack(alignment: .leading) {
                        Text(pr.title).font(.headline)
                        Text("\(pr.sourceBranch) → \(pr.targetBranch) • approvals: \(pr.approvals.count)/\(pr.requiredApprovals)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }.navigationTitle("Pull Requests")
    }
}
