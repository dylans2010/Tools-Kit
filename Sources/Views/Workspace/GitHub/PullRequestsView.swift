import SwiftUI

/// Displays a list of pull requests for a repository.
struct PullRequestsView: View {
    let owner: String
    let repo: String

    @State private var pullRequests: [GitHubPullRequest] = []
    @State private var isLoading = false
    @State private var showingCreatePR = false

    var body: some View {
        List {
            if pullRequests.isEmpty && !isLoading {
                ContentUnavailableView("No Pull Requests", systemImage: "tray.fill", description: Text("There are no open pull requests in this repository."))
            } else {
                ForEach(pullRequests) { pr in
                    ZStack {
                        NavigationLink(destination: PRDetailView(owner: owner, repo: repo, pullRequest: pr)) {
                            EmptyView()
                        }
                        .opacity(0)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(pr.title)
                                .font(.headline)
                            HStack {
                                Label("#\(pr.number)", systemImage: "circle.circle")
                                    .foregroundStyle(.secondary)
                                Text("by \(pr.user.login)")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(pr.createdAt, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Pull Requests")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCreatePR = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreatePR) {
            CreatePRView(owner: owner, repo: repo) {
                fetchPRs()
            }
        }
        .overlay {
            if isLoading { ProgressView() }
        }
        .onAppear {
            fetchPRs()
        }
    }

    private func fetchPRs() {
        isLoading = true
        Task {
            do {
                self.pullRequests = try await GitHubAPIClient.shared.request(.pullRequests(owner: owner, repo: repo))
                isLoading = false
            } catch {
                isLoading = false
            }
        }
    }
}
