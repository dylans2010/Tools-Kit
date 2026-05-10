import SwiftUI

struct PullRequestDashboardView: View {
    let spaceID: UUID
    @StateObject private var prManager = PullRequestManager.shared
    @State private var showingCreatePR = false

    var body: some View {
        List {
            if let prs = prManager.pullRequests[spaceID], !prs.isEmpty {
                ForEach(prs) { pr in
                    NavigationLink(destination: PullRequestDetailView(pr: pr)) {
                        VStack(alignment: .leading) {
                            Text(pr.title)
                                .font(.headline)
                            HStack {
                                Text("#\(pr.id.uuidString.prefix(6))")
                                Text("By \(pr.creatorName)")
                                Spacer()
                                Text(pr.status.rawValue.capitalized)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(statusColor(pr.status).opacity(0.2))
                                    .foregroundColor(statusColor(pr.status))
                                    .clipShape(Capsule())
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                Text("No pull requests for this space.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Pull Requests")
        .toolbar {
            Button(action: { showingCreatePR = true }) {
                Image(systemName: "plus.circle")
            }
        }
        .sheet(isPresented: $showingCreatePR) {
            CreatePRCollabView(spaceID: spaceID)
        }
    }

    private func statusColor(_ status: PullRequestStatus) -> Color {
        switch status {
        case .open: return .green
        case .merged: return .purple
        case .closed: return .red
        case .draft: return .secondary
        }
    }
}

struct PullRequestDetailView: View {
    let pr: PullRequest

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(pr.title)
                    .font(.largeTitle)
                    .bold()

                Text(pr.description)
                    .font(.body)

                Divider()

                HStack {
                    Label("Source: \(pr.sourceBranchID.uuidString.prefix(8))", systemImage: "arrow.triangle.pull")
                    Spacer()
                    Image(systemName: "arrow.right")
                    Spacer()
                    Label("Target: \(pr.targetBranchID.uuidString.prefix(8))", systemImage: "arrow.triangle.merge")
                }
                .font(.footnote)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)

                NavigationLink("View Changes") {
                    PRDiffView(prID: pr.id)
                }
                .buttonStyle(.borderedProminent)

                Text("Reviews")
                    .font(.headline)

                if pr.reviews.isEmpty {
                    Text("No reviews yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(pr.reviews) { review in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(review.reviewerName)
                                    .bold()
                                Spacer()
                                Text(review.isApproved ? "Approved" : "Commented")
                                    .foregroundColor(review.isApproved ? .green : .orange)
                            }
                            Text(review.comment)
                                .font(.subheadline)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("PR Details")
    }
}
