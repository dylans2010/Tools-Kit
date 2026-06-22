import SwiftUI

struct RepoDetailView: View {
    let repository: GitHubRepository
    @State private var selectedBranch: String
    @State private var showingCommandPalette = false

    init(repository: GitHubRepository) {
        self.repository = repository
        _selectedBranch = State(initialValue: repository.defaultBranch)
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: repository.owner.avatarUrl)) { image in
                        image.resizable()
                    } placeholder: {
                        Image(systemName: "person.crop.circle")
                            .font(.title)
                            .foregroundStyle(.secondary)
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
                        Label(language, systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            } header: {
                Text("Repository")
            }

            Section {
                HStack {
                    Label("Stars", systemImage: "star")
                    Spacer()
                    Text("\(repository.stargazersCount)")
                        .font(.headline)
                }

                HStack {
                    Label("Forks", systemImage: "arrow.triangle.branch")
                    Spacer()
                    Text("\(repository.forksCount)")
                        .font(.headline)
                }

                HStack {
                    Label("Watchers", systemImage: "eye")
                    Spacer()
                    Text("\(repository.watchersCount)")
                        .font(.headline)
                }
            } header: {
                Text("Statistics")
            }

            Section {
                NavigationLink(destination: GitHubProjectKanbanView(owner: repository.owner.login, repo: repository.name)) {
                    Label("Project Board", systemImage: "square.grid.3x2.fill")
                }

                NavigationLink(destination: GitHubContributionGraphView(owner: repository.owner.login, repo: repository.name)) {
                    Label("Contribution Stats", systemImage: "chart.bar.xaxis")
                }

                NavigationLink(destination: BranchListView(owner: repository.owner.login, repo: repository.name, selectedBranch: selectedBranch) { branch in
                    selectedBranch = branch
                }) {
                    Label("Branches", systemImage: "arrow.triangle.branch")
                }

                NavigationLink(destination: CommitHistoryView(owner: repository.owner.login, repo: repository.name, branch: selectedBranch)) {
                    Label("Commits", systemImage: "clock")
                }

                NavigationLink(destination: PullRequestsView(owner: repository.owner.login, repo: repository.name)) {
                    Label("Pull Requests", systemImage: "arrow.triangle.pull")
                }

                NavigationLink(destination: RepoFileExplorerView(owner: repository.owner.login, repo: repository.name, path: "", branch: selectedBranch)) {
                    Label("File Explorer", systemImage: "folder")
                }

                NavigationLink(destination: AgentHomeView(owner: repository.owner.login, repo: repository.name)) {
                    Label("Agent", systemImage: "sparkles")
                }

                NavigationLink(destination: WorkflowListView(owner: repository.owner.login, repo: repository.name)) {
                    Label("Workflows", systemImage: "play.rectangle.on.rectangle")
                }
            } header: {
                Text("Actions")
            }

            Section {
                NavigationLink(destination: GitHubToolDashboardView(owner: repository.owner.login, repo: repository.name)) {
                    Label("Intelligence Module", systemImage: "sparkles.tv")
                }
                NavigationLink(destination: CodeIntelligenceView()) {
                    Label("Code Intel", systemImage: "magnifyingglass.circle")
                }
                NavigationLink(destination: BranchIntelligenceView(owner: repository.owner.login, repo: repository.name)) {
                    Label("Branch Intel", systemImage: "arrow.branch")
                }
                NavigationLink(destination: WorkflowBuilderView()) {
                    Label("Workflow Builder", systemImage: "play.rectangle.on.rectangle")
                }
            } header: {
                Text("Intelligence")
            }

            Section {
                NavigationLink(destination: RepoToolsPanelView(owner: repository.owner.login, repo: repository.name)) {
                    Label("Repo Tools", systemImage: "wrench.and.screwdriver")
                }
                NavigationLink(destination: SecurityToolsView(owner: repository.owner.login, repo: repository.name)) {
                    Label("Security", systemImage: "lock.shield")
                }
                NavigationLink(destination: ReleaseManagerView(owner: repository.owner.login, repo: repository.name)) {
                    Label("Releases", systemImage: "tag")
                }
                NavigationLink(destination: LocalGitEngineView()) {
                    Label("Local Git Engine", systemImage: "externaldrive.connected.to.line.below")
                }
            } header: {
                Text("Tools")
            }

            Section {
                NavigationLink(destination: PluginsMainView()) {
                    Label("Plugin Extensions", systemImage: "puzzlepiece.extension")
                }
            } header: {
                Text("Extensions")
            }
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
}
