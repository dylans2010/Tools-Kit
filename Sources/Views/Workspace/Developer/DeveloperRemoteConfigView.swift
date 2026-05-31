import SwiftUI

struct DeveloperRemoteConfigView: View {
    @ObservedObject var configService = RemoteConfigService.shared
    @State private var selectedAppID: UUID?
    @State private var selectedEnvironment: KeyEnvironment = .live
    @State private var showingAddConfig = false
    @State private var searchText = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                configOverview

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Config Keys").font(.headline)
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

                    if configService.configs.isEmpty {
                        EmptyStateView(icon: "gearshape.2", title: "No Configurations", message: "Add remote configuration keys to dynamically update your app.")
                    } else {
                        ForEach(configService.configs.filter { $0.environment == selectedEnvironment }) { config in
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
    }

    private var configOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Configuration State").font(.headline)
                    Text("Last synced: \(Date().formatted(date: .abbreviated, time: .shortened))").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "cloud.fill").foregroundStyle(.blue)
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
        .padding()
    }

    private func configCard(_ config: RemoteConfig) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(config.key).font(.subheadline.monospaced()).bold()
                Spacer()
                Text(config.valueType.rawValue).font(.system(size: 8, weight: .bold))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.1), in: Capsule())
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Value:").font(.caption2.bold()).foregroundStyle(.secondary)
                Text(config.value).font(.subheadline.monospaced()).lineLimit(2)
            }

            Divider()

            HStack {
                Text("v\(config.version)").font(.system(size: 8)).foregroundStyle(.tertiary)
                Spacer()
                Button {
                    // edit logic
                } label: {
                    Text("Edit").font(.system(size: 10, weight: .bold))
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05)))
    }
}

struct AddConfigSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var configService = RemoteConfigService.shared
    let environment: KeyEnvironment

    @State private var key = ""
    @State private var value = ""
    @State private var valueType: RemoteConfigValueType = .string

    var body: some View {
        NavigationStack {
            Form {
                Section("New Configuration") {
                    TextField("Key (e.g. feature_login_v2)", text: $key)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

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

                Section {
                    Text("Configuring for \(environment.rawValue) environment.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Config")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newConfig = RemoteConfig(key: key, value: value, valueType: valueType, environment: environment, version: 1)
                        configService.addConfig(newConfig)
                        dismiss()
                    }
                    .disabled(key.isEmpty || value.isEmpty)
                }
            }
        }
    }
}
