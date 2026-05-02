import SwiftUI

/// Displays detailed information about a repository using native SwiftUI.
struct RepoDetailView: View {
    let repository: GitHubRepository
    @State private var selectedBranch: String

    init(repository: GitHubRepository) {
        self.repository = repository
        _selectedBranch = State(initialValue: repository.defaultBranch)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                statsSection
                actionsSection
            }
            .padding(16)
        }
        .navigationTitle(repository.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(destination: WorkflowListView(owner: repository.owner.login, repo: repository.name)) {
                    Text("Actions")
                }
            }
        }
    }

    private var headerSection: some View {
        WorkspaceSurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: repository.owner.avatarUrl)) { image in
                        image.resizable()
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(repository.fullName)
                            .font(.headline)
                        Text("Active Branch: \(selectedBranch)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let description = repository.description {
                    Text(description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label(repository.private ? "Private" : "Public", systemImage: repository.private ? "lock.fill" : "globe")
                    Spacer()
                    if let language = repository.language {
                        Text(language)
                    }
                }
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            }
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Statistics")
                .font(.headline)
                .padding(.leading, 4)

            HStack(spacing: 12) {
                RepoStatCard(title: "Stars", value: "\(repository.stargazersCount)", icon: "star.fill", color: .yellow)
                RepoStatCard(title: "Forks", value: "\(repository.forksCount)", icon: "arrow.triangle.branch", color: .green)
                RepoStatCard(title: "Watchers", value: "\(repository.watchersCount)", icon: "eye.fill", color: .purple)
            }
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Actions")
                .font(.headline)
                .padding(.leading, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink(destination: BranchListView(owner: repository.owner.login, repo: repository.name, selectedBranch: selectedBranch) { branch in
                    selectedBranch = branch
                }) {
                    ActionCardContent(title: "Branches", icon: "arrow.branch", color: .blue)
                }

                NavigationLink(destination: CommitHistoryView(owner: repository.owner.login, repo: repository.name, branch: selectedBranch)) {
                    ActionCardContent(title: "Commits", icon: "clock.fill", color: .green)
                }

                NavigationLink(destination: PullRequestsView(owner: repository.owner.login, repo: repository.name)) {
                    ActionCardContent(title: "Pull Requests", icon: "tray.full.fill", color: .orange)
                }

                NavigationLink(destination: RepoFileExplorerView(owner: repository.owner.login, repo: repository.name, path: "", branch: selectedBranch)) {
                    ActionCardContent(title: "Explorer", icon: "folder.fill", color: .indigo)
                }

                NavigationLink(destination: AgentHomeView(owner: repository.owner.login, repo: repository.name)) {
                    ActionCardContent(title: "Agent", icon: "sparkles", color: .pink)
                }

                NavigationLink(destination: WorkflowListView(owner: repository.owner.login, repo: repository.name)) {
                    ActionCardContent(title: "Workflows", icon: "play.rectangle.on.rectangle", color: .cyan)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

private struct RepoStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        WorkspaceSurfaceCard(padding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: icon)
                    .font(.caption2.bold())
                    .foregroundStyle(color)
                Text(value)
                    .font(.title3.bold())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ActionCardContent: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        WorkspaceSurfaceCard(padding: 12) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.12))
                    .clipShape(Circle())
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
