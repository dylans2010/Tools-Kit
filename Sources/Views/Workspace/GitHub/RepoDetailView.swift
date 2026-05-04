import SwiftUI

/// Displays detailed information about a repository using native SwiftUI.
struct RepoDetailView: View {
    let repository: GitHubRepository
    @State private var selectedBranch: String
    @State private var showingCommandPalette = false

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
                developerToolsSection
            }
            .padding(16)
        }
        .navigationTitle(repository.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                CommandPaletteButton(isShowingPalette: $showingCommandPalette)
                NavigationLink(destination: WorkflowListView(owner: repository.owner.login, repo: repository.name)) {
                    Text("Actions")
                }
            }
        }
        .overlay {
            if showingCommandPalette {
                GlobalCommandPaletteView(isPresented: $showingCommandPalette, currentView: "github")
                    .ignoresSafeArea()
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

    private var developerToolsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            RepoDetailView_Developer(repo: repository.name)

            // Intelligence
            VStack(alignment: .leading, spacing: 10) {
                Text("Intelligence")
                    .font(.headline)
                    .padding(.leading, 4)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    NavigationLink(destination: GitHubToolDashboardView(owner: repository.owner.login, repo: repository.name)) {
                        ActionCardContent(title: "Intelligence Module", icon: "sparkles.tv.fill", color: .indigo)
                    }
                    NavigationLink(destination: CodeIntelligenceView()) {
                        ActionCardContent(title: "Code Intel", icon: "magnifyingglass.circle.fill", color: .orange)
                    }
                    NavigationLink(destination: BranchIntelligenceView(owner: repository.owner.login, repo: repository.name)) {
                        ActionCardContent(title: "Branch Intel", icon: "arrow.branch", color: .blue)
                    }
                    NavigationLink(destination: WorkflowBuilderView()) {
                        ActionCardContent(title: "Workflow Builder", icon: "play.rectangle.on.rectangle", color: .purple)
                    }
                }
                .buttonStyle(.plain)
            }

            // Tools
            VStack(alignment: .leading, spacing: 10) {
                Text("Tools")
                    .font(.headline)
                    .padding(.leading, 4)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    NavigationLink(destination: RepoToolsPanelView(owner: repository.owner.login, repo: repository.name)) {
                        ActionCardContent(title: "Repo Tools", icon: "wrench.and.screwdriver.fill", color: .indigo)
                    }
                    NavigationLink(destination: SecurityToolsView(owner: repository.owner.login, repo: repository.name)) {
                        ActionCardContent(title: "Security", icon: "lock.shield.fill", color: .red)
                    }
                    NavigationLink(destination: ReleaseManagerView(owner: repository.owner.login, repo: repository.name)) {
                        ActionCardContent(title: "Releases", icon: "tag.fill", color: .green)
                    }
                    NavigationLink(destination: PluginsMainView()) {
                        ActionCardContent(title: "Plugin Tools", icon: "puzzlepiece.extension.fill", color: .blue)
                    }
                }
                .buttonStyle(.plain)
            }

            // Local Engine
            VStack(alignment: .leading, spacing: 10) {
                Text("Local Engine")
                    .font(.headline)
                    .padding(.leading, 4)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    NavigationLink(destination: LocalGitEngineView()) {
                        ActionCardContent(title: "Local Git", icon: "externaldrive.connected.to.line.below", color: .teal)
                    }
                }
                .buttonStyle(.plain)
            }
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
