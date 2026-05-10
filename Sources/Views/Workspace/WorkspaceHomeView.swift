import SwiftUI

struct WorkspaceHomeView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Workspace") {
                    NavigationLink {
                        NotesView()
                    } label: {
                        Label("Notes", systemImage: "note.text")
                    }
                    NavigationLink {
                        TasksHomeView()
                    } label: {
                        Label("Tasks", systemImage: "checklist")
                    }
                    NavigationLink {
                        FileManagementView()
                    } label: {
                        Label("Files", systemImage: "folder")
                    }
                    NavigationLink {
                        CalendarHomeView()
                    } label: {
                        Label("Calendar", systemImage: "calendar")
                    }
                }

                Section("Creation") {
                    NavigationLink {
                        NotebooksHomeView()
                    } label: {
                        Label("Notebooks", systemImage: "book.closed")
                    }
                    NavigationLink {
                        ArticlesHomeView()
                    } label: {
                        Label("Articles", systemImage: "newspaper")
                    }
                    NavigationLink {
                        EditingHomeView()
                    } label: {
                        Label("Media Editing", systemImage: "photo.stack")
                    }
                    NavigationLink {
                        SlidesHomeView()
                    } label: {
                        Label("Slides", systemImage: "rectangle.on.rectangle")
                    }
                }

                Section("System Entry") {
                    NavigationLink {
                        SDKHomeView()
                    } label: {
                        Label("SDK", systemImage: "hammer")
                    }
                    NavigationLink {
                        PluginsMainView()
                    } label: {
                        Label("Plugins", systemImage: "puzzlepiece.extension")
                    }
                    NavigationLink {
                        ConnectorsMainView()
                    } label: {
                        Label("Connectors", systemImage: "cable.connector")
                    }
                    NavigationLink {
                        SecurityHomeView()
                    } label: {
                        Label("Security", systemImage: "lock.shield")
                    }
                    NavigationLink {
                        GitHubRouterView()
                    } label: {
                        Label("GitHub", systemImage: "terminal")
                    }
                }
            }
            .navigationTitle("Workspace")
        }
        .withPluginOverlay()
    }
}

struct GitHubRouterView: View {
    @State private var isAuthenticated = false
    @State private var isLoading = true
    @State private var token: String = ""
    @State private var showingAuth = false
    @State private var authErrorMessage: String?
    @State private var isSavingToken = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if isAuthenticated {
                RepoListView()
            } else {
                ContentUnavailableView(
                    "GitHub Not Connected",
                    systemImage: "terminal",
                    description: Text("Connect your GitHub account using a Personal Access Token to manage your repositories.")
                )
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
                            token = ""
                            authErrorMessage = nil
                            showingAuth = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            Task {
                                await saveAndValidateToken()
                            }
                        }
                        .disabled(isSavingToken)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    @MainActor
    private func refreshAuthState() async {
        isLoading = true
        token = ""
        authErrorMessage = nil

        guard let storedToken = GitHubAuthManager.shared.getToken(),
              !storedToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            isAuthenticated = false
            isLoading = false
            return
        }

        let valid = await GitHubAuthManager.shared.validateToken()
        if valid {
            isAuthenticated = true
            isLoading = false
        } else {
            GitHubAuthManager.shared.deleteToken()
            isAuthenticated = false
            isLoading = false
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
        showingAuth = false
        token = ""
    }
}
