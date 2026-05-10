import SwiftUI

/// Displays the commit history for a repository.
struct CommitHistoryView: View {
    let owner: String
    let repo: String
    var branch: String? = nil

    @State private var commits: [GitHubCommit] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            ForEach(commits) { commit in
                VStack(alignment: .leading, spacing: 4) {
                    Text(commit.commit.message)
                        .font(.headline)
                        .lineLimit(2)

                    HStack {
                        if let author = commit.author {
                            AsyncImage(url: URL(string: author.avatarUrl)) { image in
                                image.resizable()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                            }
                            .frame(width: 20, height: 20)
                            .clipShape(Circle())

                            Text(author.login)
                        } else {
                            Text(commit.commit.author.name)
                        }

                        Text("•")
                        Text(commit.sha.prefix(7))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(commit.commit.author.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .swipeActions(edge: .trailing) {
                    Button {
                        revertCommit(commit)
                    } label: {
                        Label("Revert", systemImage: "arrow.uturn.backward")
                    }
                    .tint(.secondary)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Commits")
        .overlay {
            if isLoading { ProgressView() }
        }
        .onAppear {
            fetchCommits()
        }
        .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown Error")
        }
    }

    private func fetchCommits() {
        isLoading = true
        Task {
            do {
                let fetched: [GitHubCommit] = try await GitHubAPIClient.shared.request(.commits(owner: owner, repo: repo, sha: branch))
                await MainActor.run {
                    self.commits = fetched
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    private func revertCommit(_ commit: GitHubCommit) {

        let revertPrompt = "Revert the changes made in commit \(commit.sha) (\(commit.commit.message))"

        Task {
            do {
                // We'll use Jules to handle the complex Git logic of reverting
                let _ = try await AgentSessionManager.shared.startSession(prompt: revertPrompt, owner: owner, repo: repo, branch: branch)
                await MainActor.run {
                    self.errorMessage = "Started Agent Task to revert commit."
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to start revert: \(error.localizedDescription)"
                }
            }
        }
    }
}
