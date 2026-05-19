import SwiftUI

// MARK: - AIChatSettingsRouter

private struct AIChatSettingsRouter: View {
    @StateObject private var settingsManager = AIChatSettingsManager.shared

    var body: some View {
        AIChatSettingsView(settings: $settingsManager.settings)
    }
}

// MARK: - GitHubTokenStore

private class GitHubTokenStore {
    static let shared = GitHubTokenStore()
    private let key = "github_pat_token"
    private init() {}

    func getToken() -> String? {
        UserDefaults.standard.string(forKey: key)
    }

    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: key)
    }

    func validate(_ token: String) async throws {
        guard !token.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }
    }
}

struct WorkspaceNavItem: Identifiable, Codable, Equatable {
    let id: String
    let label: String
    let icon: String
    let section: String
    var isVisible: Bool

    enum CodingKeys: String, CodingKey {
        case id, label, icon, section, isVisible
    }
}

class WorkspaceNavConfig: ObservableObject {
    static let shared = WorkspaceNavConfig()
    private let storageKey = "workspace_nav_config"

    @Published var items: [WorkspaceNavItem] = []

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([WorkspaceNavItem].self, from: data),
           !saved.isEmpty {
            items = saved
        } else {
            items = Self.defaultItems
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func resetToDefaults() {
        items = Self.defaultItems
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func toggleVisibility(for id: String) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].isVisible.toggle()
            save()
        }
    }

    var visibleItems: [WorkspaceNavItem] {
        items.filter(\.isVisible)
    }

    func visibleItems(in section: String) -> [WorkspaceNavItem] {
        items.filter { $0.section == section && $0.isVisible }
    }

    var sections: [String] {
        var seen: [String] = []
        for item in items {
            if !seen.contains(item.section) { seen.append(item.section) }
        }
        return seen
    }

    static let defaultItems: [WorkspaceNavItem] = [
        WorkspaceNavItem(id: "notes", label: "Notes", icon: "note.text", section: "Workspace", isVisible: true),
        WorkspaceNavItem(id: "tasks", label: "Tasks", icon: "checklist", section: "Workspace", isVisible: true),
        WorkspaceNavItem(id: "files", label: "Files", icon: "folder", section: "Workspace", isVisible: true),
        WorkspaceNavItem(id: "calendar", label: "Calendar", icon: "calendar", section: "Workspace", isVisible: true),
        WorkspaceNavItem(id: "spreadsheets", label: "Spreadsheets", icon: "tablecells", section: "Workspace", isVisible: true),
        WorkspaceNavItem(id: "habits", label: "Habits", icon: "flame", section: "Workspace", isVisible: true),

        WorkspaceNavItem(id: "notebooks", label: "Notebooks", icon: "book.closed", section: "Creation", isVisible: true),
        WorkspaceNavItem(id: "articles", label: "Articles", icon: "newspaper", section: "Creation", isVisible: true),
        WorkspaceNavItem(id: "editing", label: "Media Editing", icon: "photo.stack", section: "Creation", isVisible: true),
        WorkspaceNavItem(id: "slides", label: "Slides", icon: "rectangle.on.rectangle", section: "Creation", isVisible: true),
        WorkspaceNavItem(id: "whiteboards", label: "Whiteboards", icon: "scribble.variable", section: "Creation", isVisible: true),

        WorkspaceNavItem(id: "agentic", label: "Agentic System", icon: "sparkles", section: "Collaboration", isVisible: true),
        WorkspaceNavItem(id: "persona", label: "Persona", icon: "brain.head.profile", section: "Collaboration", isVisible: true),
        WorkspaceNavItem(id: "collaboration", label: "Collaboration", icon: "person.2", section: "Collaboration", isVisible: true),
        WorkspaceNavItem(id: "meetings", label: "Meetings", icon: "video", section: "Collaboration", isVisible: true),
        WorkspaceNavItem(id: "automations", label: "Automations", icon: "bolt", section: "Collaboration", isVisible: true),
        WorkspaceNavItem(id: "integrations", label: "Integrations", icon: "square.grid.3x3", section: "Collaboration", isVisible: true),
        WorkspaceNavItem(id: "timetravel", label: "Time Travel", icon: "clock.arrow.circlepath", section: "Collaboration", isVisible: true),

        WorkspaceNavItem(id: "sdk", label: "SDK", icon: "hammer", section: "System", isVisible: true),
        WorkspaceNavItem(id: "plugins", label: "Plugins", icon: "puzzlepiece.extension", section: "System", isVisible: true),
        WorkspaceNavItem(id: "connectors", label: "Connectors", icon: "cable.connector", section: "System", isVisible: true),
        WorkspaceNavItem(id: "security", label: "Security", icon: "lock.shield", section: "System", isVisible: true),
        WorkspaceNavItem(id: "securitysetup", label: "Security Setup", icon: "shield.checkered", section: "System", isVisible: true),
        WorkspaceNavItem(id: "github", label: "GitHub", icon: "terminal", section: "System", isVisible: true),

        WorkspaceNavItem(id: "mail", label: "Mail", icon: "envelope", section: "Settings", isVisible: true),
    ]
}

struct WorkspaceHomeView: View {
    @StateObject private var mailStore = MailStore.shared
    @StateObject private var authorizationManager = AuthorizationManager.shared
    @StateObject private var navConfig = WorkspaceNavConfig.shared
    @State private var showingSignIn = false
    @State private var isEditMode = false

    private var hasMailAccounts: Bool {
        !mailStore.accounts.isEmpty
    }

    private func handleSDKAccess() {
        authorizationManager.tryAutoAuthenticate()
        if authorizationManager.authState != .authenticated {
            showingSignIn = true
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isEditMode {
                    editModeContent
                } else {
                    normalContent
                }
            }
            .navigationTitle("Workspace")
            .sheet(isPresented: $showingSignIn) {
                NavigationStack { SignInView() }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isEditMode.toggle()
                        }
                    } label: {
                        Text(isEditMode ? "Done" : "Edit")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        AIChatSettingsRouter()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .withPluginOverlay()
    }

    // MARK: - Normal Content

    private var normalContent: some View {
        List {
            ForEach(navConfig.sections, id: \.self) { section in
                let sectionItems = navConfig.visibleItems(in: section)
                if !sectionItems.isEmpty {
                    Section(section) {
                        ForEach(sectionItems) { item in
                            navLink(for: item)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Edit Mode

    private var editModeContent: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    Text("Drag to reorder items. Toggle visibility with the eye icon.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button(role: .destructive) {
                    navConfig.resetToDefaults()
                } label: {
                    Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                }
            }

            ForEach(navConfig.sections, id: \.self) { section in
                Section(section) {
                    let sectionItems = navConfig.items.filter { $0.section == section }
                    ForEach(sectionItems) { item in
                        HStack {
                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(.secondary)
                                .font(.caption)

                            Label(item.label, systemImage: item.icon)
                                .foregroundStyle(item.isVisible ? .primary : .tertiary)

                            Spacer()

                            Button {
                                navConfig.toggleVisibility(for: item.id)
                            } label: {
                                Image(systemName: item.isVisible ? "eye.fill" : "eye.slash")
                                    .foregroundStyle(item.isVisible ? .blue : .secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .onMove { source, destination in
                        moveWithinSection(section: section, source: source, destination: destination)
                    }
                }
            }
        }
        .environment(\.editMode, .constant(.active))
    }

    private func moveWithinSection(section: String, source: IndexSet, destination: Int) {
        let sectionItems = navConfig.items.filter { $0.section == section }
        var mutableSection = sectionItems
        mutableSection.move(fromOffsets: source, toOffset: destination)

        var newItems = navConfig.items.filter { $0.section != section }
        if let firstIndex = navConfig.items.firstIndex(where: { $0.section == section }) {
            newItems.insert(contentsOf: mutableSection, at: min(firstIndex, newItems.count))
        } else {
            newItems.append(contentsOf: mutableSection)
        }
        navConfig.items = newItems
        navConfig.save()
    }

    // MARK: - Navigation Links

    @ViewBuilder
    private func navLink(for item: WorkspaceNavItem) -> some View {
        switch item.id {
        case "notes":
            NavigationLink { NotesView() } label: { Label(item.label, systemImage: item.icon) }
        case "tasks":
            NavigationLink { TasksHomeView() } label: { Label(item.label, systemImage: item.icon) }
        case "files":
            NavigationLink { FileManagementView() } label: { Label(item.label, systemImage: item.icon) }
        case "calendar":
            NavigationLink { CalendarHomeView() } label: { Label(item.label, systemImage: item.icon) }
        case "spreadsheets":
            NavigationLink { SpreadsheetsHomeView() } label: { Label(item.label, systemImage: item.icon) }
        case "habits":
            NavigationLink { WorkspaceHabitTrackerView() } label: { Label(item.label, systemImage: item.icon) }
        case "notebooks":
            NavigationLink { NotebooksHomeView() } label: { Label(item.label, systemImage: item.icon) }
        case "articles":
            NavigationLink { ArticlesHomeView() } label: { Label(item.label, systemImage: item.icon) }
        case "editing":
            NavigationLink { EditingHomeView() } label: { Label(item.label, systemImage: item.icon) }
        case "slides":
            NavigationLink { SlidesHomeView() } label: { Label(item.label, systemImage: item.icon) }
        case "whiteboards":
            NavigationLink { WhiteboardsHomeView() } label: { Label(item.label, systemImage: item.icon) }
        case "agentic":
            NavigationLink { AgenticUIHomeView() } label: { Label(item.label, systemImage: item.icon) }
        case "persona":
            NavigationLink { PersonaHomeView() } label: { Label(item.label, systemImage: item.icon) }
        case "collaboration":
            NavigationLink { CollaborationHomeView() } label: { Label(item.label, systemImage: item.icon) }
        case "meetings":
            NavigationLink { JoinMeetingView() } label: { Label(item.label, systemImage: item.icon) }
        case "automations":
            NavigationLink { AutomationHomeView() } label: { Label(item.label, systemImage: item.icon) }
        case "integrations":
            NavigationLink { IntegrationsHomeView() } label: { Label(item.label, systemImage: item.icon) }
        case "timetravel":
            NavigationLink { TimeTravelHomeView() } label: { Label(item.label, systemImage: item.icon) }
        case "sdk":
            if authorizationManager.authState == .authenticated {
                NavigationLink { SDKHomeView() } label: { Label(item.label, systemImage: item.icon) }
            } else {
                Button { handleSDKAccess() } label: {
                    Label("SDK (Sign In Required)", systemImage: item.icon).foregroundStyle(.secondary)
                }
            }
        case "plugins":
            if authorizationManager.authState == .authenticated {
                NavigationLink { PluginsMainView() } label: { Label(item.label, systemImage: item.icon) }
            } else {
                Button { handleSDKAccess() } label: {
                    Label("Plugins (Sign In Required)", systemImage: item.icon).foregroundStyle(.secondary)
                }
            }
        case "connectors":
            if authorizationManager.authState == .authenticated {
                NavigationLink { ConnectorsMainView() } label: { Label(item.label, systemImage: item.icon) }
            } else {
                Button { handleSDKAccess() } label: {
                    Label("Connectors (Sign In Required)", systemImage: item.icon).foregroundStyle(.secondary)
                }
            }
        case "security":
            NavigationLink { SecurityHomeView() } label: { Label(item.label, systemImage: item.icon) }
        case "securitysetup":
            NavigationLink { SecurityOnboardingView(authService: AuthService.shared) } label: { Label(item.label, systemImage: item.icon) }
        case "github":
            NavigationLink { GitHubRouterView() } label: { Label(item.label, systemImage: item.icon) }
        case "mail":
            if hasMailAccounts {
                NavigationLink { UniversalInboxView() } label: { Label(item.label, systemImage: item.icon) }
            } else {
                NavigationLink { ManageAccountsView() } label: { Label(item.label, systemImage: item.icon) }
            }
        default:
            EmptyView()
        }
    }
}

struct WorkspaceSettingsView: View {
    var body: some View {
        List {
            Section("Account") {
                NavigationLink { ManageAccountsView() } label: {
                    Label("Mail Accounts", systemImage: "envelope")
                }
            }

            Section("Preferences") {
                NavigationLink { SecurityHomeView() } label: {
                    Label("Security", systemImage: "lock.shield")
                }
                NavigationLink { SecurityOnboardingView(authService: AuthService.shared) } label: {
                    Label("Security Setup", systemImage: "shield.checkered")
                }
            }

            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Build", value: "2026.5")
            }
        }
        .navigationTitle("Settings")
    }
}

struct GitHubRouterView: View {
    @State private var isAuthenticated = false
    @State private var isLoading = true
    @State private var token: String = ""
    @State private var showingAuth = false
    @State private var authErrorMessage: String?
    @State private var isSavingToken = false

    private var isSaveDisabled: Bool {
        isSavingToken || token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if isAuthenticated {
                RepoListView()
            } else {
                ContentUnavailableView {
                    Label("GitHub Not Connected", systemImage: "terminal")
                } description: {
                    Text("Connect your GitHub account using a Personal Access Token to manage your repositories.")
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Connect") {
                            showingAuth = true
                        }
                    }
                }
            }
        }
        .navigationTitle("GitHub")
        .task {
            await refreshAuthState()
        }
        .sheet(isPresented: $showingAuth) {
            NavigationStack {
                Form {
                    SecureField("Personal Access Token", text: $token)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    if let authErrorMessage {
                        Text(authErrorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .navigationTitle("Connect GitHub")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingAuth = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveToken()
                        }
                        .disabled(isSaveDisabled)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func refreshAuthState() async {
        let stored = GitHubTokenStore.shared.getToken()
        await MainActor.run {
            isAuthenticated = stored != nil
            isLoading = false
        }
    }

    private func saveToken() {
        isSavingToken = true
        authErrorMessage = nil
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            do {
                try await GitHubTokenStore.shared.validate(trimmed)
                GitHubTokenStore.shared.saveToken(trimmed)
                await MainActor.run {
                    isAuthenticated = true
                    isSavingToken = false
                    showingAuth = false
                }
            } catch {
                await MainActor.run {
                    authErrorMessage = error.localizedDescription
                    isSavingToken = false
                }
            }
        }
    }
}
