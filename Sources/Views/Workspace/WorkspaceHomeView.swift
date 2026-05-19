import SwiftUI

struct WorkspaceHomeView: View {
    @StateObject private var mailStore = MailStore.shared
    @StateObject private var authorizationManager = AuthorizationManager.shared
    @State private var showingSignIn = false
    @Environment(\.editMode) private var editMode

    @State private var sections: [HomeSection] = WorkspaceHomeView.defaultSections

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
            List {
                ForEach($sections) { $section in
                    Section(section.title) {
                        let filteredIndices = Array(section.items.enumerated()).filter { $0.element.isVisible || editMode?.wrappedValue.isEditing == true }.map { $0.offset }

                        ForEach(filteredIndices, id: \.self) { index in
                            HomeRow(item: $section.items[index], authManager: authorizationManager, onAuthRequired: handleSDKAccess)
                        }
                        .onMove { indices, newOffset in
                            section.items.move(fromOffsets: indices, toOffset: newOffset)
                            saveLayout()
                        }
                    }
                }

                Section("Mail & Settings") {
                    if hasMailAccounts {
                        NavigationLink { UniversalInboxView() } label: {
                            Label("Mail", systemImage: "envelope")
                        }
                    } else {
                        NavigationLink { ManageAccountsView() } label: {
                            Label("Mail", systemImage: "envelope")
                        }
                    }
                }
            }
            .navigationTitle("Workspace")
            .sheet(isPresented: $showingSignIn) {
                NavigationStack {
                    SignInView()
                }
            }
            .onAppear {
                // Remove auto sign-in on appear, let handleSDKAccess manage it
            }
            .onAppear(perform: loadLayout)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
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
}

// MARK: - Models

struct HomeSection: Identifiable, Codable {
    let id: String
    var title: String
    var items: [HomeItem]
}

struct HomeItem: Identifiable, Codable {
    let id: String
    var title: String
    var icon: String
    var destination: AnyView?
    var requiresAuth: Bool = false
    var isVisible: Bool = true

    enum CodingKeys: String, CodingKey {
        case id, title, icon, requiresAuth, isVisible
    }

    init(id: String, title: String, icon: String, destination: AnyView? = nil, requiresAuth: Bool = false, isVisible: Bool = true) {
        self.id = id; self.title = title; self.icon = icon; self.destination = destination; self.requiresAuth = requiresAuth; self.isVisible = isVisible
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        icon = try container.decode(String.self, forKey: .icon)
        requiresAuth = try container.decode(Bool.self, forKey: .requiresAuth)
        isVisible = try container.decode(Bool.self, forKey: .isVisible)
        destination = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(icon, forKey: .icon)
        try container.encode(requiresAuth, forKey: .requiresAuth)
        try container.encode(isVisible, forKey: .isVisible)
    }
}

// MARK: - Helper Views

struct HomeRow: View {
    @Binding var item: HomeItem
    let authManager: AuthorizationManager
    let onAuthRequired: () -> Void
    @Environment(\.editMode) private var editMode

    var body: some View {
        if editMode?.wrappedValue.isEditing == true {
            Button {
                item.isVisible.toggle()
            } label: {
                HStack {
                    Label(item.title, systemImage: item.icon)
                        .foregroundStyle(item.isVisible ? .primary : .secondary)
                    Spacer()
                    Image(systemName: item.isVisible ? "eye" : "eye.slash")
                        .foregroundStyle(item.isVisible ? .blue : .secondary)
                }
            }
            .buttonStyle(.plain)
        } else {
            if item.requiresAuth && authManager.authState != .authenticated {
                Button(action: onAuthRequired) {
                    Label("\(item.title) (Sign In Required)", systemImage: item.icon)
                        .foregroundStyle(.secondary)
                }
            } else if let dest = item.destination {
                NavigationLink {
                    dest
                } label: {
                    Label(item.title, systemImage: item.icon)
                }
            }
        }
    }
}

// MARK: - Persistence

extension WorkspaceHomeView {
    static let defaultSections: [HomeSection] = [
        HomeSection(id: "workspace", title: "Workspace", items: [
            HomeItem(id: "notes", title: "Notes", icon: "note.text", destination: AnyView(NotesView())),
            HomeItem(id: "tasks", title: "Tasks", icon: "checklist", destination: AnyView(TasksHomeView())),
            HomeItem(id: "files", title: "Files", icon: "folder", destination: AnyView(FileManagementView())),
            HomeItem(id: "calendar", title: "Calendar", icon: "calendar", destination: AnyView(CalendarHomeView())),
            HomeItem(id: "spreadsheets", title: "Spreadsheets", icon: "tablecells", destination: AnyView(SpreadsheetsHomeView())),
            HomeItem(id: "habits", title: "Habits", icon: "flame", destination: AnyView(WorkspaceHabitTrackerView()))
        ]),
        HomeSection(id: "creation", title: "Creation", items: [
            HomeItem(id: "notebooks", title: "Notebooks", icon: "book.closed", destination: AnyView(NotebooksHomeView())),
            HomeItem(id: "articles", title: "Articles", icon: "newspaper", destination: AnyView(ArticlesHomeView())),
            HomeItem(id: "media", title: "Media Editing", icon: "photo.stack", destination: AnyView(EditingHomeView())),
            HomeItem(id: "slides", title: "Slides", icon: "rectangle.on.rectangle", destination: AnyView(SlidesHomeView())),
            HomeItem(id: "whiteboards", title: "Whiteboards", icon: "scribble.variable", destination: AnyView(WhiteboardsHomeView()))
        ]),
        HomeSection(id: "collaboration", title: "Collaboration", items: [
            HomeItem(id: "agentic", title: "Agentic System", icon: "sparkles", destination: AnyView(AgenticUIHomeView())),
            HomeItem(id: "persona", title: "Persona", icon: "brain.head.profile", destination: AnyView(PersonaHomeView())),
            HomeItem(id: "collaboration_main", title: "Collaboration", icon: "person.2", destination: AnyView(CollaborationHomeView())),
            HomeItem(id: "meetings", title: "Meetings", icon: "video", destination: AnyView(JoinMeetingView())),
            HomeItem(id: "automations", title: "Automations", icon: "bolt", destination: AnyView(AutomationHomeView())),
            HomeItem(id: "integrations", title: "Integrations", icon: "square.grid.3x3", destination: AnyView(IntegrationsHomeView())),
            HomeItem(id: "timetravel", title: "Time Travel", icon: "clock.arrow.circlepath", destination: AnyView(TimeTravelHomeView()))
        ]),
        HomeSection(id: "system", title: "System", items: [
            HomeItem(id: "sdk", title: "SDK", icon: "hammer", destination: AnyView(SDKHomeView()), requiresAuth: true),
            HomeItem(id: "plugins", title: "Plugins", icon: "puzzlepiece.extension", destination: AnyView(PluginsMainView()), requiresAuth: true),
            HomeItem(id: "connectors", title: "Connectors", icon: "cable.connector", destination: AnyView(ConnectorsMainView()), requiresAuth: true),
            HomeItem(id: "security", title: "Security", icon: "lock.shield", destination: AnyView(SecurityHomeView())),
            HomeItem(id: "github", title: "GitHub", icon: "terminal", destination: AnyView(GitHubRouterView()))
        ])
    ]

    private func saveLayout() {
        if let encoded = try? JSONEncoder().encode(sections) {
            UserDefaults.standard.set(encoded, forKey: "workspace_home_layout_v3")
        }
    }

    private func loadLayout() {
        guard let data = UserDefaults.standard.data(forKey: "workspace_home_layout_v3"),
              var decoded = try? JSONDecoder().decode([HomeSection].self, from: data) else { return }

        // Restore destinations which aren't Codable
        for sIdx in decoded.indices {
            for iIdx in decoded[sIdx].items.indices {
                let itemId = decoded[sIdx].items[iIdx].id
                if let originalItem = findOriginalItem(id: itemId) {
                    decoded[sIdx].items[iIdx].destination = originalItem.destination
                }
            }
        }
        self.sections = decoded
    }

    private func findOriginalItem(id: String) -> HomeItem? {
        for section in WorkspaceHomeView.defaultSections {
            if let item = section.items.first(where: { $0.id == id }) {
                return item
            }
        }
        return nil
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
                        Button("Cancel") {
                            resetAuthSheet()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            Task {
                                await saveAndValidateToken()
                            }
                        }
                        .disabled(isSaveDisabled)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    @MainActor
    private func refreshAuthState() async {
        isLoading = true
        defer { isLoading = false }
        resetAuthSheet()

        guard let storedToken = GitHubAuthManager.shared.getToken(),
              !storedToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            isAuthenticated = false
            return
        }

        let valid = await GitHubAuthManager.shared.validateToken()
        if valid {
            isAuthenticated = true
        } else {
            GitHubAuthManager.shared.deleteToken()
            isAuthenticated = false
        }
    }

    @MainActor
    private func saveAndValidateToken() async {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            authErrorMessage = "Please enter a valid Personal Access Token."
            return
        }

        isSavingToken = true
        authErrorMessage = nil

        let didSave = GitHubAuthManager.shared.saveToken(trimmed)
        guard didSave else {
            isSavingToken = false
            authErrorMessage = "Unable to save token. Please try again."
            return
        }

        let valid = await GitHubAuthManager.shared.validateToken()
        isSavingToken = false

        guard valid else {
            GitHubAuthManager.shared.deleteToken()
            authErrorMessage = "Token validation failed. Check scopes and try again."
            return
        }

        isAuthenticated = true
        resetAuthSheet()
    }

    private func resetAuthSheet() {
        token = ""
        authErrorMessage = nil
        showingAuth = false
    }
}

struct AIChatSettingsRouter: View {
    @StateObject private var settingsManager = AIChatSettingsManager.shared

    var body: some View {
        AIChatSettingsView(settings: $settingsManager.settings)
    }
}
