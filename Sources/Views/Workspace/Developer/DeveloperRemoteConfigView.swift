import SwiftUI

enum APIKeyEnvironment: String, CaseIterable, Hashable {
    case development, staging, production, sandbox, live
}

struct DeveloperRemoteConfigView: View {
    @ObservedObject var configService = RemoteConfigService.shared
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?
    @State private var selectedEnvironment: APIKeyEnvironment = .sandbox
    @State private var showingAddConfig = false

    var filteredConfigs: [RemoteConfig] {
        configService.configs.filter { config in
            (selectedAppID == nil || config.appID == selectedAppID) &&
            (config.environment == (selectedEnvironment == .live ? .live : .test))
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                configOverviewHeader

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Config Keys").font(.headline)
                        Spacer()
                        Button { showingAddConfig = true } label: {
                            Image(systemName: "plus.circle.fill").font(.title3)
                        }
                    }

                    Picker("Environment", selection: $selectedEnvironment) {
                        Text("Sandbox").tag(APIKeyEnvironment.sandbox)
                        Text("Live").tag(APIKeyEnvironment.live)
                    }
                    .pickerStyle(.segmented)

                    if filteredConfigs.isEmpty {
                        EmptyStateView(icon: "gearshape.2", title: "No Configurations", message: "Add remote configuration keys to dynamically update your application state without code changes.")
                            .padding(.vertical, 40)
                    } else {
                        ForEach(filteredConfigs) { config in
                            configCard(config)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Remote Config")
        .background(Color(uiColor: .systemGroupedBackground))
        .sheet(isPresented: $showingAddConfig) {
            AddConfigSheet(appID: selectedAppID, environment: selectedEnvironment)
        }
        .onAppear {
            if selectedAppID == nil { selectedAppID = appService.apps.first?.id }
        }
    }

    private var configOverviewHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sync Integrity").font(.headline)
                    Text("Fleet-wide consistency verified").font(.caption).foregroundStyle(.green)
                }
                Spacer()
                Image(systemName: "cloud.fill").foregroundStyle(.blue).font(.title2)
            }

            HStack(spacing: 32) {
                VStack(alignment: .leading) {
                    Text("\(filteredConfigs.count)").font(.title3.bold())
                    Text("ACTIVE KEYS").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading) {
                    Text("12.4ms").font(.title3.bold())
                    Text("AVG PROPAGATION").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))
        .padding()
    }

    private func configCard(_ config: RemoteConfig) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(config.key).font(.subheadline.monospaced()).bold()
                Spacer()
                Text(config.valueType.rawValue.uppercased()).font(.system(size: 8, weight: .black))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Value").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary).textCase(.uppercase)
                Text(config.value).font(.subheadline.monospaced()).lineLimit(2)
            }

            Divider()

            HStack {
                Text("Version \(config.version)").font(.system(size: 8)).foregroundStyle(.tertiary)
                Spacer()
                Button {
                    // edit logic
                } label: {
                    Text("Modify").font(.system(size: 10, weight: .bold))
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }
}

private struct AddConfigView: View {
    var body: some View {
        Text("Add Configuration")
    }
}

struct AddConfigSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var configService = RemoteConfigService.shared
    @ObservedObject var appService = DeveloperAppService.shared

    @State private var appID: UUID?
    let environment: APIKeyEnvironment

    @State private var key = ""
    @State private var value = ""
    @State private var valueType: RemoteConfigValueType = .string

    init(appID: UUID?, environment: APIKeyEnvironment) {
        self._appID = State(initialValue: appID)
        self.environment = environment
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Target Application") {
                    Picker("App", selection: $appID) {
                        ForEach(appService.apps) { app in
                            Text(app.name).tag(Optional(app.id))
                        }
                    }
                }

                Section("Configuration Details") {
                    TextField("Config Key", text: $key, prompt: Text("e.g. session_timeout"))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    Picker("Value Type", selection: $valueType) {
                        ForEach(RemoteConfigValueType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Value").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $value).frame(height: 100).font(.system(.subheadline, design: .monospaced))
                    }
                }
            }
            .navigationTitle("New Configuration")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveConfig()
                    }
                    .disabled(key.isEmpty || value.isEmpty || appID == nil)
                }
            }
        }
    }

    private func saveConfig() {
        guard let appID else { return }
        let env: KeyEnvironment = (environment == .live ? .live : .test)
        let newConfig = RemoteConfig(appID: appID, key: key, value: value, valueType: valueType, environment: env, version: 1)
        configService.addConfig(newConfig)
        dismiss()
    }
}
