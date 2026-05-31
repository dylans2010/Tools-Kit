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
                        }
                    }
                } else {
                    Text("Select an app to manage environments.").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Sandbox Environments")
        .safeAreaInset(edge: .top) {
            NavigationLink(destination: SandboxEnvironmentView()) {
                HStack {
                    Image(systemName: "testtube.2").foregroundStyle(.secondary)
                    Text("Legacy Sandbox Settings").font(.subheadline)
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
            }
            .buttonStyle(.plain)
        }
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
}
