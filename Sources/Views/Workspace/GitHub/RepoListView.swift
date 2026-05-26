import SwiftUI

/// Displays a list of repositories for the authenticated user using native SwiftUI.
struct RepoListView: View {
    @State private var repositories: [GitHubRepository] = []
    @State private var filteredRepositories: [GitHubRepository] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""

    var body: some View {
        Group {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        NavigationLink(destination: GitHubTrendingExplorerView()) {
                            QuickGitHubTool(title: "Trending", icon: "chart.line.uptrend.xyaxis", color: .orange)
                        }
                        NavigationLink(destination: GitHubRepoComparisonView()) {
                            QuickGitHubTool(title: "Compare", icon: "arrow.left.and.right.square", color: .blue)
                        }
                    }
                    .padding()
                }
                .background(Color(.secondarySystemBackground))

                if isLoading && repositories.isEmpty {
                    ProgressView("Fetching Repositories...")
                } else if repositories.isEmpty && !isLoading {
                ContentUnavailableView(
                    "No Repositories",
                    systemImage: "folder.badge.questionmark",
                    description: Text("We couldn't find any repositories for your account.")
                )
            } else {
                List {
                    ForEach(displayRepositories) { repo in
                        NavigationLink(destination: RepoDetailView(repository: repo)) {
                            RepoRow(repository: repo)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .swipeActions(edge: .trailing) {
                            Button {
                                toggleStar(for: repo)
                            } label: {
                                Label("Star", systemImage: "star.fill")
                            }
                            .tint(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await fetchRepositories()
                }
            }
        }
        .navigationTitle("Repositories")
        .searchable(text: $searchText, prompt: "Search Repositories")
        .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown Error")
        }
        .task {
            await fetchRepositories()
        }
        .onChange(of: searchText) { _, _ in
            filterRepositories()
        }
    }

    private var displayRepositories: [GitHubRepository] {
        searchText.isEmpty ? repositories : filteredRepositories
    }

    private func fetchRepositories() async {
        isLoading = true
        do {
            let repos: [GitHubRepository] = try await GitHubAPIClient.shared.request(.userRepos)
            await MainActor.run {
                self.repositories = repos
                self.isLoading = false
                filterRepositories()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    private func filterRepositories() {
        if searchText.isEmpty {
            filteredRepositories = repositories
        } else {
            filteredRepositories = repositories.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private func toggleStar(for repo: GitHubRepository) {
        Task {
            do {
                try await GitHubAPIClient.shared.requestEmpty(.starred(owner: repo.owner.login, repo: repo.name))

            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to star repository: \(error.localizedDescription)"
                }
            }
        }
    }
}

private struct QuickGitHubTool: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title).font(.caption.bold())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1), in: Capsule())
        .foregroundStyle(color)
    }
}

private struct RepoRow: View {
    let repository: GitHubRepository

    var body: some View {
        WorkspaceSurfaceCard(padding: 12) {
            HStack(spacing: 14) {
                Image(systemName: repository.private ? "lock.fill" : "book.closed.fill")
                    .font(.title3)
                    .frame(width: 40, height: 40)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(repository.name)
                        .font(.headline)
                    if let description = repository.description {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                        Text("\(repository.stargazersCount)")
                    }
                    .font(.caption2.bold())
                    Text(repository.language ?? "Mixed")
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
    }
}
