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
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(commit.commit.author.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
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
            Text(errorMessage ?? "Unknown error")
        }
    }

    private func fetchCommits() {
        isLoading = true
        Task {
            do {
                self.commits = try await GitHubAPIClient.shared.request(.commits(owner: owner, repo: repo, sha: branch))
                isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
