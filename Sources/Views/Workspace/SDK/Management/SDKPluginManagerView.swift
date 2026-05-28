

import SwiftUI

struct SDKPluginManagerView: View {
    @StateObject private var runtime = PluginRuntimeEngine.shared
    @StateObject private var authorizationManager = AuthorizationManager.shared
    @State private var showingAddApp = false
    @State private var searchText = ""

    private var filteredApps: [SDKAppDefinition] {
        if searchText.isEmpty { return runtime.loadedApps }
        return runtime.loadedApps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) || $0.author.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Installed Apps", value: "\(runtime.loadedApps.count)")
                LabeledContent("Running Contexts", value: "\(runtime.runningApps.count)").foregroundStyle(.green).bold()
                LabeledContent("Sandboxed", value: "\(runtime.loadedApps.filter { $0.isSandboxed }.count)").foregroundStyle(Color.accentColor)
            } header: {
                Text("System Status")
            }

            Section(header: Text("Registry")) {
                if filteredApps.isEmpty {
                    ContentUnavailableView("No Extensions Found", systemImage: "puzzlepiece.extension", description: Text("Register an app to extend workspace capabilities."))
                } else {
                    ForEach(filteredApps) { app in
                        PluginAppRow(app: app, runtime: runtime, authorizationManager: authorizationManager)
                    }
                    .onDelete(perform: deleteApps)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Plugin Manager")
        .searchable(text: $searchText, prompt: "Search applications")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddApp = true } label: { Label("Add", systemImage: "plus") }
            }
        }
        .sheet(isPresented: $showingAddApp) {
            AddPluginAppSheet(runtime: runtime)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private func deleteApps(at offsets: IndexSet) {
        for index in offsets { runtime.unregister(appId: filteredApps[index].id) }
    }
}

// MARK: - Private Subviews

private struct PluginAppRow: View {
    let app: SDKAppDefinition
    @ObservedObject var runtime: PluginRuntimeEngine
    @ObservedObject var authorizationManager: AuthorizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(app.name).font(.headline)
                        if app.madeForWorkspace { Image(systemName: "checkmark.seal.fill").font(.caption2).foregroundStyle(.blue) }
                    }
                    Text("v\(app.version) by \(app.author.isEmpty ? "Internal" : app.author)").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()

                Button(runtime.isRunning(app.id) ? "Stop" : "Start") {
                    Task {
                        if runtime.isRunning(app.id) { try? await runtime.stop(appId: app.id) }
                        else { try? await runtime.start(appId: app.id) }
                    }
                }
                .buttonStyle(.bordered).controlSize(.small).tint(runtime.isRunning(app.id) ? .red : .green)
                .disabled(!authorizationManager.canUseScopes(app.requiredScopes))
            }

            if !app.description.isEmpty {
                Text(app.description).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }

            HStack(spacing: 8) {
                if app.isSandboxed { Label("Sandboxed", systemImage: "lock.shield").foregroundStyle(Color.accentColor) }
                if !app.permissions.isEmpty { Text(app.permissions.joined(separator: ", ")).foregroundStyle(.tertiary) }
            }
            .font(.system(size: 9, weight: .bold, design: .monospaced))
        }
        .padding(.vertical, 4)
    }
}

private struct AddPluginAppSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var runtime: PluginRuntimeEngine
    @State private var name = ""
    @State private var version = "1.0.0"
    @State private var author = ""
    @State private var description = ""
    @State private var permissions = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("App Details")) {
                    TextField("Name", text: $name)
                    TextField("Version", text: $version)
                    TextField("Author", text: $author)
                    TextField("Description", text: $description, axis: .vertical).lineLimit(3)
                }
                Section(header: Text("Permissions")) {
                    TextField("e.g. read, write, network", text: $permissions).font(.caption.monospaced())
                }
                Section {
                    Button("Register Application") {
                        let perms = permissions.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                        let app = SDKAppDefinition(name: name, version: version, author: author, description: description, permissions: perms)
                        try? runtime.register(app)
                        dismiss()
                    }
                    .disabled(name.isEmpty).frame(maxWidth: .infinity).bold()
                }
            }
            .navigationTitle("Register App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}
