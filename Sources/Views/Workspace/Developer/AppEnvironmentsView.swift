import SwiftUI

struct AppEnvironmentsView: View {
    let appID: UUID
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var keyService = APIKeyService.shared
    @State private var showingAddEnvironment = false
    @State private var newEnvName = ""
    @State private var newEnvURL = ""

    var app: DeveloperApp? {
        appService.apps.first { $0.id == appID }
    }

    var body: some View {
        List {
            if let app = app {
                if app.environments.isEmpty {
                    Section {
                        EmptyStateView(icon: "server.rack", title: "No Environments", message: "Create isolation environments for your app.")
                    }
                } else {
                    ForEach(app.environments) { env in
                        Section(env.name) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("API Base URL").font(.caption.bold()).foregroundStyle(.secondary)
                                Text(env.apiBaseURL).font(.subheadline)

                                Divider().padding(.vertical, 4)

                                Text("Assigned Keys").font(.caption.bold()).foregroundStyle(.secondary)
                                let envKeys = keyService.keys.filter { env.assignedKeyIDs.contains($0.id) }
                                if envKeys.isEmpty {
                                    Text("No keys assigned.").font(.caption).foregroundStyle(.secondary)
                                } else {
                                    ForEach(envKeys) { key in
                                        HStack {
                                            Text(key.label).font(.caption.bold())
                                            Spacer()
                                            Text(key.maskedValue).font(.system(size: 8, design: .monospaced))
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .onDelete(perform: deleteEnvironments)
                }
            }
        }
        .navigationTitle("Environments")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddEnvironment = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAddEnvironment) {
            addEnvironmentSheet
        }
    }

    private var addEnvironmentSheet: some View {
        NavigationStack {
            Form {
                Section("Environment Details") {
                    TextField("Name (Development, Staging, etc.)", text: $newEnvName)
                    TextField("API Base URL", text: $newEnvURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("New Environment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddEnvironment = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addEnvironment() }
                        .disabled(newEnvName.isEmpty || newEnvURL.isEmpty)
                }
            }
        }
    }

    private func addEnvironment() {
        guard var updatedApp = app else { return }
        let newEnv = AppEnvironment(name: newEnvName, apiBaseURL: newEnvURL)
        updatedApp.environments.append(newEnv)

        Task {
            try? await appService.updateApp(updatedApp)
            await MainActor.run {
                showingAddEnvironment = false
                newEnvName = ""
                newEnvURL = ""
            }
        }
    }

    private func deleteEnvironments(at offsets: IndexSet) {
        guard var updatedApp = app else { return }
        updatedApp.environments.remove(atOffsets: offsets)
        Task {
            try? await appService.updateApp(updatedApp)
        }
    }
}
