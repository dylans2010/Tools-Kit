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
            Section("Management Scope") {
                Picker("App Filter", selection: $selectedAppID) {
                    Text("Select an Application").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Application Environments") {
                if let app = selectedApp {
                    if app.environments.isEmpty {
                        EmptyStateView(icon: "square.dashed", title: "No Environments", message: "Configure a sandbox or staging environment to test your application in isolation.")
                    } else {
                        ForEach(app.environments) { env in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(env.name).font(.subheadline.bold())
                                Text(env.apiBaseURL).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                            .swipeActions {
                                Button(role: .destructive) { deleteSandbox(env.id) } label: { Label("Delete", systemImage: "trash") }
                            }
                        }
                    }
                } else {
                    Text("Choose an application to manage its isolated runtime environments.").font(.caption).foregroundStyle(.secondary)
                }
            }

            if selectedApp != nil {
                Section {
                    Button { showingAddSandbox = true } label: {
                        Label("Add Testing Environment", systemImage: "plus.circle.fill").font(.subheadline.bold())
                    }
                }
            }
        }
        .navigationTitle("Sandbox Environments")
        .sheet(isPresented: $showingAddSandbox) { addSandboxSheet }
        .onAppear {
            if selectedAppID == nil { selectedAppID = appService.apps.first?.id }
        }
    }

    private var addSandboxSheet: some View {
        NavigationStack {
            Form {
                Section("Environment Identity") {
                    TextField("Name (e.g. Staging Beta)", text: $newName)
                    TextField("Base API URL", text: $newURL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
            }
            .navigationTitle("New Sandbox")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddSandbox = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Register") { addSandbox() }
                        .disabled(newName.isEmpty || newURL.isEmpty)
                }
            }
        }
    }

    private func addSandbox() {
        guard let appID = selectedAppID, var app = appService.apps.first(where: { $0.id == appID }) else { return }
        let env = AppEnvironment(name: newName, apiBaseURL: newURL)
        app.environments.append(env)
        Task {
            try? await appService.updateApp(app)
            await MainActor.run {
                showingAddSandbox = false
                newName = ""
                newURL = ""
            }
        }
    }

    private func deleteSandbox(_ id: UUID) {
        guard let appID = selectedAppID, var app = appService.apps.first(where: { $0.id == appID }) else { return }
        app.environments.removeAll { $0.id == id }
        Task { try? await appService.updateApp(app) }
    }
}
