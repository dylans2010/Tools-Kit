import SwiftUI

struct AppEnvironmentsView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?
    @State private var showingAddEnv = false
    @State private var newName = ""
    @State private var newURL = ""

    var app: DeveloperApp? {
        appService.apps.first { $0.id == selectedAppID }
    }

    var body: some View {
        List {
            Section("Target Application") {
                Picker("App", selection: $selectedAppID) {
                    Text("Select App").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            if let app = app {
                Section("Base Environments") {
                    if app.environments.isEmpty {
                        Text("No environments configured for this application.").font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(app.environments) { env in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(env.name).font(.subheadline.bold())
                                Text(env.apiBaseURL).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                            .swipeActions {
                                Button(role: .destructive) {
                                    deleteEnv(env.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Environments")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddEnv = true } label: { Image(systemName: "plus") }
                    .disabled(selectedAppID == nil)
            }
        }
        .sheet(isPresented: $showingAddEnv) {
            NavigationStack {
                Form {
                    Section("Environment Details") {
                        TextField("Name of environment", text: $newName)
                        TextField("API Base URL", text: $newURL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                }
                .navigationTitle("New Environment")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddEnv = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") { addEnv() }
                            .disabled(newName.isEmpty || newURL.isEmpty)
                    }
                }
            }
        }
        .onAppear {
            if selectedAppID == nil { selectedAppID = appService.apps.first?.id }
        }
    }

    private func addEnv() {
        guard let appID = selectedAppID, var app = appService.apps.first(where: { $0.id == appID }) else { return }
        let env = AppEnvironment(name: newName, apiBaseURL: newURL)
        app.environments.append(env)
        Task {
            try? await appService.updateApp(app)
            await MainActor.run {
                showingAddEnv = false
                newName = ""
                newURL = ""
            }
        }
    }

    private func deleteEnv(_ id: UUID) {
        guard let appID = selectedAppID, var app = appService.apps.first(where: { $0.id == appID }) else { return }
        app.environments.removeAll { $0.id == id }
        Task {
            try? await appService.updateApp(app)
        }
    }
}
