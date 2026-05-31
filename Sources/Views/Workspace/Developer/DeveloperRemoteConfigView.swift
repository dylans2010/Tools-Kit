import SwiftUI

struct DeveloperRemoteConfigView: View {
    @ObservedObject var configService = RemoteConfigService.shared
    @State private var selectedEnvironment: KeyEnvironment = .live
    @State private var showingAddConfig = false
    @State private var editingConfig: RemoteConfig?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                configOverview

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Configurations").font(.headline)
                        Spacer()
                        Button { showingAddConfig = true } label: {
                            Image(systemName: "plus.circle.fill").font(.title3)
                        }
                    }

                    Picker("Environment", selection: $selectedEnvironment) {
                        ForEach(KeyEnvironment.allCases, id: \.self) { env in
                            Text(env.rawValue).tag(env)
                        }
                    }
                    .pickerStyle(.segmented)

                    let configs = configService.configs.filter { $0.environment == selectedEnvironment }
                    if configs.isEmpty {
                        EmptyStateView(icon: "gearshape.2", title: "No Configurations", message: "Add remote configuration keys to dynamically update your app behavior.")
                    } else {
                        ForEach(configs) { config in
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
            AddConfigSheet(environment: selectedEnvironment)
        }
        .sheet(item: $editingConfig) { config in
            EditConfigSheet(config: config)
        }
    }

    private var configOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Configuration State").font(.headline)
                    Text("Last synced: \(Date().formatted(date: .abbreviated, time: .shortened))").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "cloud.fill").foregroundStyle(.secondary)
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("\(configService.configs.count)").font(.title3.bold())
                    Text("Total Keys").font(.caption2).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading) {
                    Text("12.4ms").font(.title3.bold())
                    Text("Avg Latency").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding([.horizontal, .top])
    }

    private func configCard(_ config: RemoteConfig) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(config.key).font(.subheadline.monospaced()).bold()
                Spacer()
                Text(config.valueType.rawValue.uppercased()).font(.system(size: 8, weight: .bold))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.primary.opacity(0.05), in: Capsule())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Value").font(.caption2.bold()).foregroundStyle(.secondary)
                Text(config.value).font(.subheadline.monospaced()).lineLimit(3)
            }

            Divider()

            HStack {
                Text("v\(config.version)").font(.system(size: 8)).foregroundStyle(.tertiary)
                Spacer()
                HStack(spacing: 16) {
                    Button(role: .destructive) {
                        Task { try? await configService.deleteConfig(id: config.id) }
                    } label: {
                        Image(systemName: "trash").font(.caption)
                    }

                    Button {
                        editingConfig = config
                    } label: {
                        Text("Edit").font(.system(size: 10, weight: .bold))
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct EditConfigSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var configService = RemoteConfigService.shared
    let config: RemoteConfig

    @State private var value: String
    @State private var valueType: RemoteConfigValueType

    init(config: RemoteConfig) {
        self.config = config
        _value = State(initialValue: config.value)
        _valueType = State(initialValue: config.valueType)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Update Configuration") {
                    Text(config.key).font(.subheadline.monospaced()).foregroundStyle(.secondary)

                    Picker("Type", selection: $valueType) {
                        ForEach(RemoteConfigValueType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("Value").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $value).frame(height: 100).font(.system(.subheadline, design: .monospaced))
                    }
                }
            }
            .navigationTitle("Edit Config")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Update") {
                        Task {
                            try? await configService.updateConfig(id: config.id, value: value, type: valueType)
                            await MainActor.run { dismiss() }
                        }
                    }
                    .disabled(value.isEmpty)
                }
            }
        }
    }
}
