import SwiftUI

/// Plugin Manager — install, manage, and control SDK apps and plugins.
struct SDKPluginManagerView: View {
    @StateObject private var runtime = PluginRuntimeEngine.shared
    @State private var showingAddApp = false
    @State private var newAppName = ""
    @State private var newAppVersion = "1.0.0"
    @State private var newAppAuthor = ""
    @State private var newAppDescription = ""
    @State private var newAppPermissions = ""
    @State private var searchText = ""

    private var filteredApps: [SDKAppDefinition] {
        if searchText.isEmpty { return runtime.loadedApps }
        return runtime.loadedApps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.author.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            statsSection
            appsSection
        }
        .searchable(text: $searchText, prompt: "Search Plugins")
        .navigationTitle("Plugin Manager")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddApp = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddApp) {
            addAppSheet
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        Section {
            HStack(spacing: 20) {
                VStack {
                    Text("\(runtime.loadedApps.count)")
                        .font(.title2).bold()
                    Text("Installed")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                VStack {
                    Text("\(runtime.runningApps.count)")
                        .font(.title2).bold().foregroundStyle(.green)
                    Text("Running")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                VStack {
                    Text("\(runtime.loadedApps.filter { $0.isSandboxed }.count)")
                        .font(.title2).bold().foregroundStyle(.blue)
                    Text("Sandboxed")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        } header: {
            Text("Overview")
        }
    }

    // MARK: - Apps List

    private var appsSection: some View {
        Section {
            if filteredApps.isEmpty {
                ContentUnavailableView("No Apps Installed", systemImage: "puzzlepiece.extension", description: Text("Register an app to get started."))
            } else {
                ForEach(filteredApps) { app in
                    appRow(app)
                }
                .onDelete(perform: deleteApps)
            }
        } header: {
            Text("Apps & Plugins (\(filteredApps.count))")
        }
    }

    private func appRow(_ app: SDKAppDefinition) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(app.name).font(.subheadline).bold()
                        if app.madeForWorkspace {
                            Text("Made For Workspace")
                                .font(.system(size: 8, weight: .semibold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(
                                    LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    Text("v\(app.version) by \(app.author.isEmpty ? "Unknown" : app.author)")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()

                if runtime.isRunning(app.id) {
                    Button("Stop") {
                        Task { try? await runtime.stop(appId: app.id) }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.red)
                } else {
                    Button("Start") {
                        Task { try? await runtime.start(appId: app.id) }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.green)
                }
            }

            if !app.description.isEmpty {
                Text(app.description).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }

            HStack(spacing: 6) {
                if app.isSandboxed {
                    Label("Sandboxed", systemImage: "lock.shield.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.blue)
                }
                if !app.permissions.isEmpty {
                    Text(app.permissions.joined(separator: ", "))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Add App Sheet

    private var addAppSheet: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $newAppName)
                    TextField("Version", text: $newAppVersion)
                    TextField("Author", text: $newAppAuthor)
                    TextField("Description", text: $newAppDescription)
                } header: {
                    Text("App Details")
                }
                Section {
                    TextField("read, write, network", text: $newAppPermissions)
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("Permissions (comma-separated)")
                }
            }
            .navigationTitle("Register App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddApp = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Register") { registerApp() }
                        .disabled(newAppName.isEmpty)
                }
            }
        }
    }

    private func registerApp() {
        let permissions = newAppPermissions
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let app = SDKAppDefinition(
            name: newAppName,
            version: newAppVersion,
            author: newAppAuthor,
            description: newAppDescription,
            permissions: permissions
        )

        try? runtime.register(app)
        resetForm()
        showingAddApp = false
    }

    private func deleteApps(at offsets: IndexSet) {
        for index in offsets {
            let app = filteredApps[index]
            runtime.unregister(appId: app.id)
        }
    }

    private func resetForm() {
        newAppName = ""
        newAppVersion = "1.0.0"
        newAppAuthor = ""
        newAppDescription = ""
        newAppPermissions = ""
    }
}
