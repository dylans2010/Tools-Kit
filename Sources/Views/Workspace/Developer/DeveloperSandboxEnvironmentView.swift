import SwiftUI

struct DeveloperSandboxEnvironmentView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var showingAddSandbox = false
    @State private var newName = ""
    @State private var newURL = ""
    @State private var selectedAppID: UUID?

    var selectedApp: DeveloperApp? {
        appService.apps.first { $0.id == selectedAppID }
    }

    var body: some View {
        List {
            Section {
                Picker("App", selection: $selectedAppID) {
                    Text("Select an App").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Environments") {
                if let app = selectedApp {
                    if app.environments.isEmpty {
                        Text("No sandbox environments configured.").font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(app.environments) { env in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(env.name).font(.subheadline.bold())
                                    Text(env.apiBaseURL).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    deleteEnvironment(env.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                } else {
                    Text("Select an app to manage environments.").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Sandbox Environments")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddSandbox = true } label: { Image(systemName: "plus") }
                    .disabled(selectedAppID == nil)
            }
        }
        .sheet(isPresented: $showingAddSandbox) {
            addSandboxSheet
        }
    }

    private var addSandboxSheet: some View {
        NavigationStack {
            Form {
                TextField("Environment Name", text: $newName)
                TextField("API Base URL", text: $newURL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .navigationTitle("Add Environment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddSandbox = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addSandbox() }
                        .disabled(newName.isEmpty || newURL.isEmpty)
                }
            }
        }
    }

    private func addSandbox() {
        guard let appID = selectedAppID else { return }
        let env = AppEnvironment(name: newName, apiBaseURL: newURL)
        Task {
            if var app = appService.apps.first(where: { $0.id == appID }) {
                app.environments.append(env)
                try? await appService.updateApp(app)
            }
            await MainActor.run {
                showingAddSandbox = false
                newName = ""
                newURL = ""
            }
        }
    }

    private func deleteEnvironment(_ id: UUID) {
        guard let appID = selectedAppID else { return }
        Task {
            if var app = appService.apps.first(where: { $0.id == appID }) {
                app.environments.removeAll { $0.id == id }
                try? await appService.updateApp(app)
            }
        }
    }
}
