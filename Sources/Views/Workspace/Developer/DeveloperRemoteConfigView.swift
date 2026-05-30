import SwiftUI

struct DeveloperRemoteConfigView: View {
    @ObservedObject var configService = RemoteConfigService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?
    @State private var showingAddConfig = false
    @State private var newKey = ""
    @State private var newValue = ""

    var filteredConfigs: [RemoteConfig] {
        configService.configs.filter { selectedAppID == nil || $0.appID == selectedAppID }
    }

    var body: some View {
        List {
            Section {
                Picker("App", selection: $selectedAppID) {
                    Text("Select a Project").tag(Optional<UUID>.none)
                    ForEach(appService.apps) { app in
                        Text(app.name).tag(Optional(app.id))
                    }
                }
            }

            Section("Remote Configuration") {
                if let appID = selectedAppID {
                    if filteredConfigs.isEmpty {
                        EmptyStateView(icon: "gearshape.2", title: "No Configurations", message: "Add dynamic configuration keys to control your app remotely.")
                    } else {
                        ForEach(filteredConfigs) { config in
                            VStack(alignment: .leading) {
                                Text(config.key).font(.subheadline.bold()).monospaced()
                                Text(config.value).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                } else {
                    Text("Select a project to manage remote configurations.").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Remote Config")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAddConfig = true } label: { Image(systemName: "plus") }
                    .disabled(selectedAppID == nil)
            }
        }
        .sheet(isPresented: $showingAddConfig) {
            addConfigSheet
        }
    }

    private var addConfigSheet: some View {
        NavigationStack {
            Form {
                Section("Configuration Entry") {
                    TextField("Key", text: $newKey).monospaced()
                    TextField("Value", text: $newValue)
                }
            }
            .navigationTitle("Add Config Key")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingAddConfig = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let appID = selectedAppID {
                            let config = RemoteConfig(appID: appID, key: newKey, value: newValue)
                            Task {
                                try? await configService.saveConfig(config)
                                await MainActor.run {
                                    showingAddConfig = false
                                    newKey = ""
                                    newValue = ""
                                }
                            }
                        }
                    }
                    .disabled(newKey.isEmpty)
                }
            }
        }
    }
}
