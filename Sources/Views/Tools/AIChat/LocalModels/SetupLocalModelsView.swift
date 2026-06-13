import SwiftUI

struct SetupLocalModelsView: View {
    @ObservedObject var settingsManager = AIChatSettingsManager.shared
    @State private var showingAddSheet = false
    @State private var configToEdit: LocalModelConfig?

    var body: some View {
        List {
            Section {
                if settingsManager.settings.localConfigs.isEmpty {
                    Text("No local model configurations found.")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(settingsManager.settings.localConfigs) { config in
                        configRow(config)
                    }
                    .onDelete(perform: deleteConfigs)
                }
            } header: {
                Text("Configurations")
            } footer: {
                Text("Swipe left to delete a configuration.")
            }

            Section {
                Button {
                    configToEdit = LocalModelConfig()
                    showingAddSheet = true
                } label: {
                    Label("Add Local Model", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("Local Models")
        .sheet(item: $configToEdit) { config in
            NavigationStack {
                EditLocalModelConfigView(config: config) { updatedConfig in
                    saveConfig(updatedConfig)
                }
            }
        }
    }

    private func configRow(_ config: LocalModelConfig) -> some View {
        Button {
            configToEdit = config
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(config.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(config.baseURL)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if settingsManager.settings.selectedLocalConfigID == config.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
    }

    private func saveConfig(_ config: LocalModelConfig) {
        if let index = settingsManager.settings.localConfigs.firstIndex(where: { $0.id == config.id }) {
            settingsManager.settings.localConfigs[index] = config
        } else {
            settingsManager.settings.localConfigs.append(config)
        }

        if settingsManager.settings.selectedLocalConfigID == nil {
            settingsManager.settings.selectedLocalConfigID = config.id
        }
    }

    private func deleteConfigs(at offsets: IndexSet) {
        settingsManager.settings.localConfigs.remove(atOffsets: offsets)
        if let selectedID = settingsManager.settings.selectedLocalConfigID,
           !settingsManager.settings.localConfigs.contains(where: { $0.id == selectedID }) {
            settingsManager.settings.selectedLocalConfigID = settingsManager.settings.localConfigs.first?.id
        }
    }
}

struct EditLocalModelConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @State var config: LocalModelConfig
    var onSave: (LocalModelConfig) -> Void

    @State private var testingConnection = false
    @State private var testResult: Result<String, Error>?
    @State private var newHeaderKey = ""
    @State private var newHeaderValue = ""

    var body: some View {
        Form {
            Section("General") {
                TextField("Configuration Name", text: $config.name)
                TextField("Base URL", text: $config.baseURL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                TextField("Model Name", text: $config.modelName)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                SecureField("API Key (Optional)", text: $config.apiKey)
            }

            Section("Custom Headers") {
                ForEach(config.customHeaders.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    HStack {
                        Text(key).font(.caption.bold())
                        Spacer()
                        Text(value).font(.caption).foregroundColor(.secondary)
                        Button(role: .destructive) {
                            config.customHeaders.removeValue(forKey: key)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                        }
                        .buttonStyle(.borderless)
                    }
                }

                VStack(spacing: 8) {
                    HStack {
                        TextField("Key", text: $newHeaderKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                        TextField("Value", text: $newHeaderValue)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                    }
                    Button("Add Header") {
                        guard !newHeaderKey.isEmpty && !newHeaderValue.isEmpty else { return }
                        config.customHeaders[newHeaderKey] = newHeaderValue
                        newHeaderKey = ""
                        newHeaderValue = ""
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(newHeaderKey.isEmpty || newHeaderValue.isEmpty)
                }
                .padding(.top, 4)
            }

            Section("Model Parameters") {
                HStack {
                    Text("Temperature: \(config.temperature, specifier: "%.1f")")
                    Spacer()
                    Slider(value: $config.temperature, in: 0...2, step: 0.1)
                        .frame(width: 150)
                }

                Stepper("Max Tokens: \(config.maxTokens)", value: $config.maxTokens, in: 128...128000, step: 128)

                HStack {
                    Text("Top-P: \(config.topP, specifier: "%.2f")")
                    Spacer()
                    Slider(value: $config.topP, in: 0...1, step: 0.05)
                        .frame(width: 150)
                }

                HStack {
                    Text("Frequency Penalty: \(config.frequencyPenalty, specifier: "%.1f")")
                    Spacer()
                    Slider(value: $config.frequencyPenalty, in: -2...2, step: 0.1)
                        .frame(width: 150)
                }

                HStack {
                    Text("Presence Penalty: \(config.presencePenalty, specifier: "%.1f")")
                    Spacer()
                    Slider(value: $config.presencePenalty, in: -2...2, step: 0.1)
                        .frame(width: 150)
                }

                Stepper("Timeout: \(Int(config.timeout))s", value: $config.timeout, in: 5...300, step: 5)
            }

            Section("Testing") {
                Button {
                    testConnection()
                } label: {
                    HStack {
                        if testingConnection {
                            ProgressView().padding(.trailing, 8)
                        }
                        Text("Test Connection")
                    }
                }
                .disabled(testingConnection || config.baseURL.isEmpty)

                if let result = testResult {
                    switch result {
                    case .success(let message):
                        Label(message, systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    case .failure(let error):
                        Label(error.localizedDescription, systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }

            Section {
                Button("Set as Default") {
                    AIChatSettingsManager.shared.settings.selectedLocalConfigID = config.id
                }
                .disabled(AIChatSettingsManager.shared.settings.selectedLocalConfigID == config.id)
            }
        }
        .navigationTitle(config.name.isEmpty ? "New Local Model" : config.name)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    onSave(config)
                    dismiss()
                }
                .disabled(config.name.isEmpty || config.baseURL.isEmpty)
            }
        }
    }

    private func testConnection() {
        testingConnection = true
        testResult = nil

        Task {
            do {
                // Determine test endpoint
                let testPath = config.baseURL.contains("/v1") ? "/models" : "/api/tags"
                let cleanBase = config.baseURL
                    .replacingOccurrences(of: "/chat/completions", with: "")
                    .replacingOccurrences(of: "/v1", with: "")

                guard let url = URL(string: cleanBase + (config.baseURL.contains("/v1") ? "/v1" : "") + testPath) else {
                    throw NSError(domain: "LocalModels", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Test URL"])
                }

                var request = URLRequest(url: url)
                request.timeoutInterval = 10
                if !config.apiKey.isEmpty {
                    request.addValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
                }
                config.customHeaders.forEach { request.addValue($1, forHTTPHeaderField: $0) }

                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    let body = String(data: data, encoding: .utf8) ?? "No body"
                    throw NSError(domain: "LocalModels", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned \(statusCode): \(body)"])
                }

                await MainActor.run {
                    self.testResult = .success("Connection successful! Found models.")
                    self.testingConnection = false
                }
            } catch {
                await MainActor.run {
                    self.testResult = .failure(error)
                    self.testingConnection = false
                }
            }
        }
    }
}
