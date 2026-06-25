import SwiftUI

struct SetupLocalModelsView: View {
    @ObservedObject var settingsManager = AIChatSettingsManager.shared
    @AppStorage("aichat_selected_provider") private var selectedProviderID = "openrouter"
    @AppStorage("aichat_model_id") private var modelID = ""

    @State private var showingManualAdd = false
    @State private var configToEdit: LocalModelConfig?
    @State private var fetchedModels: [AIModel] = []
    @State private var isFetching = false
    @State private var fetchError: String?

    var body: some View {
        List {

            Section {
                if settingsManager.settings.localConfigs.isEmpty {
                    Text("No custom providers configured.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(settingsManager.settings.localConfigs) { config in
                        customConfigRow(config)
                    }
                    .onDelete(perform: deleteConfigs)
                }

                Button(action: {
                    configToEdit = LocalModelConfig()
                    showingManualAdd = true
                }) {
                    Label("Add Custom Endpoint", systemImage: "plus.circle")
                        .font(.subheadline.bold())
                }
            } header: {
                SectionHeader(title: "Custom Providers", subtitle: "Manual Ollama, vLLM, or OpenAI-compat", icon: "terminal")
                    .listRowInsets(EdgeInsets())
                    .padding(.bottom, 8)
            }

            Section {
                AFMSelectionSection()
            } header: {
                SectionHeader(title: "Native AI", subtitle: "Apple Foundation Models", icon: "apple.logo")
                    .listRowInsets(EdgeInsets())
                    .padding(.bottom, 8)
            }

            Section {
                NavigationLink(destination: HuggingFaceBrowseView()) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.1))
                                .frame(width: 44, height: 44)
                            Image(systemName: "face.smiling")
                                .foregroundColor(.orange)
                                .font(.title3)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("HuggingFace")
                                .font(.headline)
                            Text("Browse & download GGUF models")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            } header: {
                SectionHeader(title: "Cloud Repositories", subtitle: "Download models from the community", icon: "icloud.and.arrow.down")
                    .listRowInsets(EdgeInsets())
                    .padding(.bottom, 8)
            }

            Section {
                let currentModels = activeConfig?.cachedModels ?? []
                if currentModels.isEmpty {
                    Text("No models fetched for this provider yet.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(currentModels) { model in
                        NavigationLink(destination: LocalModelDetailsView(model: model, config: activeConfig ?? LocalModelConfig())) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(model.name)
                                        .font(.headline)
                                    Text(model.id)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()

                                Button {
                                    toggleFavorite(model)
                                } label: {
                                    Image(systemName: isFavorite(model) ? "star.fill" : "star")
                                        .foregroundColor(isFavorite(model) ? .yellow : .gray)
                                }
                                .buttonStyle(.plain)

                                if modelID == model.id && selectedProviderID == "local_models" {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            } header: {
                SectionHeader(title: "Active Models", subtitle: "Models from your local providers", icon: "square.stack.3d.up")
                    .listRowInsets(EdgeInsets())
                    .padding(.bottom, 8)
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

    private func customConfigRow(_ config: LocalModelConfig) -> some View {
        Button {
            selectManualConfig(config)
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(config.name)
                        .font(.headline)
                    Text(config.baseURL)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if settingsManager.settings.selectedLocalConfigID == config.id && selectedProviderID == "local_models" {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.orange)
                }

                Button(action: { configToEdit = config }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        }
    }

    private func selectManualConfig(_ config: LocalModelConfig) {
        settingsManager.settings.selectedLocalConfigID = config.id
        settingsManager.settings.selectedProviderID = "local_models"
        selectedProviderID = "local_models"
        modelID = config.modelName
        settingsManager.settings.modelID = config.modelName
    }

    private var activeConfig: LocalModelConfig? {
        guard let configID = settingsManager.settings.selectedLocalConfigID else { return nil }
        return settingsManager.settings.localConfigs.first(where: { $0.id == configID })
    }

    private func saveConfig(_ config: LocalModelConfig) {
        if let index = settingsManager.settings.localConfigs.firstIndex(where: { $0.id == config.id }) {
            settingsManager.settings.localConfigs[index] = config
        } else {
            settingsManager.settings.localConfigs.append(config)
        }
    }

    private func deleteConfigs(at offsets: IndexSet) {
        settingsManager.settings.localConfigs.remove(atOffsets: offsets)
    }

    private func selectModel(_ model: AIModel) {
        modelID = model.id
        settingsManager.settings.modelID = model.id
        selectedProviderID = "local_models"
        settingsManager.settings.selectedProviderID = "local_models"
    }

    private func toggleFavorite(_ model: AIModel) {
        if let index = settingsManager.settings.favoriteModels.firstIndex(where: { $0.id == model.id }) {
            settingsManager.settings.favoriteModels.remove(at: index)
        } else {
            settingsManager.settings.favoriteModels.append(model)
        }
    }

    private func isFavorite(_ model: AIModel) -> Bool {
        settingsManager.settings.favoriteModels.contains(where: { $0.id == model.id })
    }
}

struct AFMSelectionSection: View {
    @StateObject private var afmManager = AFMModelManager.shared
    @AppStorage("aichat_selected_provider") private var selectedProviderID = "openrouter"
    @AppStorage("aichat_model_id") private var modelID = ""

    var body: some View {
        ForEach(afmManager.availableModels, id: \.self) { model in
            Button {
                selectAFM(model)
            } label: {
                HStack {
                    Text(model)
                        .font(.headline)
                    Spacer()
                    if selectedProviderID == "afm" && modelID == model {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }

    private func selectAFM(_ model: String) {
        AIChatSettingsManager.shared.settings.selectedProviderID = "afm"
        selectedProviderID = "afm"
        modelID = model
        AIChatSettingsManager.shared.settings.modelID = model
        AIChatSettingsManager.shared.settings.selectedAFMModelID = model
        AIChatSettingsManager.shared.settings.selectedLocalConfigID = nil
    }
}

struct EditLocalModelConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("aichat_selected_provider") private var selectedProviderID = "openrouter"
    @AppStorage("aichat_model_id") private var modelID = ""
    @State var config: LocalModelConfig
    var onSave: (LocalModelConfig) -> Void

    @State private var showingAdvanced = false
    @State private var isValidating = false
    @State private var validationError: String?
    @State private var diagnostics: [String] = []
    @State private var detectedProvider: LocalProviderType = .unknown
    @State private var showingOllamaSetup = false

    var body: some View {
        Form {
            Section {
                Button {
                    showingOllamaSetup = true
                } label: {
                    Label("Use Ollama Instead", systemImage: "sparkles")
                        .foregroundColor(.orange)
                        .bold()
                }
                .navigationDestination(isPresented: $showingOllamaSetup) {
                    OllamaSetupView(config: $config) { updatedConfig in
                        onSave(updatedConfig)
                        dismiss()
                    }
                }
            }

            Section {
                TextField("Friendly Name (e.g. My PC)", text: $config.name)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Chat Endpoint")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("http://localhost:11434/v1/chat/completions", text: $config.baseURL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .font(.system(.body, design: .monospaced))
                }
            } header: {
                Text("Inference Server")
            } footer: {
                Text("Enter the full URL for chat completions. Everything else will be derived automatically.")
            }

            Section {
                Button(action: startOnboarding) {
                    HStack {
                        if isValidating {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Text(isValidating ? "Validating..." : "Connect & Discover Models")
                            .bold()
                    }
                }
                .disabled(isValidating || config.baseURL.isEmpty)

                if !diagnostics.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(diagnostics, id: \.self) { log in
                            Text(log)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(log.contains("FAILED") ? .red : .secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if let error = validationError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption.bold())
                }
            }

            if !config.cachedModels.isEmpty {
                Section {
                    Picker("Active Model", selection: $config.modelName) {
                        ForEach(config.cachedModels) { model in
                            Text(model.name).tag(model.id)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Available Models")
                }
            }

            Section {
                SecureField("API Key (Optional)", text: $config.apiKey)
            } header: {
                Text("Authentication")
            }

            Section {
                Button(action: { showingAdvanced = true }) {
                    Label("Advanced Parameters", systemImage: "slider.horizontal.3")
                }

                if detectedProvider != .unknown {
                    LabeledContent("Detected Provider", value: detectedProvider.rawValue)
                }
            }

            Section {
                Button {
                    AIChatSettingsManager.shared.settings.selectedLocalConfigID = config.id
                    AIChatSettingsManager.shared.settings.selectedProviderID = "local_models"
                    selectedProviderID = "local_models"
                    modelID = config.modelName
                    onSave(config)
                    dismiss()
                } label: {
                    HStack {
                        Spacer()
                        Text("Set as Active Configuration")
                            .bold()
                        Spacer()
                    }
                }
                .disabled(config.name.isEmpty || config.baseURL.isEmpty || config.modelName.isEmpty || isValidating)
            }
        }
        .navigationTitle(config.name.isEmpty ? "New Endpoint" : config.name)
        .sheet(isPresented: $showingAdvanced) {
            NavigationStack {
                AdvancedLocalModelsConfigView(config: $config)
            }
        }
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

    private func startOnboarding() {
        isValidating = true
        validationError = nil
        diagnostics = []

        Task {
            let result = await LocalModelService.shared.validateAndDiscover(
                endpoint: config.baseURL,
                apiKey: config.apiKey
            )

            await MainActor.run {
                self.isValidating = false
                self.diagnostics = result.diagnostics

                if result.success {
                    self.config.cachedModels = result.models
                    self.detectedProvider = result.provider
                    if self.config.modelName.isEmpty || !result.models.contains(where: { $0.id == self.config.modelName }) {
                        self.config.modelName = result.models.first?.id ?? ""
                    }
                    onSave(config)
                } else {
                    self.validationError = result.error
                }
            }
        }
    }
}

struct LocalModelsByDefault: View {
    var body: some View {
        SetupLocalModelsView()
    }
}

// MARK: - Ollama Specific Logic

struct OllamaConfig {
    static func normalizeEndpoint(_ input: String) -> String {
        var url = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if !url.starts(with: "http") {
            url = "http://\(url)"
        }
        if url.hasSuffix("/") {
            url = String(url.dropLast())
        }
        return url
    }

    static func fetchModels(endpoint: String) async throws -> [AIModel] {
        let baseURL = normalizeEndpoint(endpoint)
        guard let url = URL(string: "\(baseURL)/api/tags") else {
            throw AIError.invalidEndpoint
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw AIError.invalidResponse
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(OllamaTagsResponse.self, from: data)
        return result.models.map { m in
            AIModel(id: m.name, name: m.name, supportsVision: m.name.contains("llava") || m.name.contains("vision"))
        }
    }

    static func sendChat(endpoint: String, model: String, messages: [ChatMessage], parameters: [String: Any] = [:]) async throws -> String {
        let baseURL = normalizeEndpoint(endpoint)
        guard let url = URL(string: "\(baseURL)/api/chat") else {
            throw AIError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = parameters
        body["model"] = model
        body["messages"] = messages.map { ["role": $0.role, "content": $0.content] }
        body["stream"] = false

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw AIError.requestFailed("Ollama returned status \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let message = json?["message"] as? [String: Any], let content = message["content"] as? String {
            return content
        }

        throw AIError.decodingFailed
    }
}

private struct OllamaTagsResponse: Codable {
    let models: [OllamaTagModel]
}

private struct OllamaTagModel: Codable {
    let name: String
}

// MARK: - Ollama Setup UI

struct OllamaSetupView: View {
    @Binding var config: LocalModelConfig
    var onComplete: (LocalModelConfig) -> Void

    @State private var isFetching = false
    @State private var errorMessage: String?
    @State private var diagnostics: [String] = []
    @AppStorage("aichat_selected_provider") private var selectedProviderID = "openrouter"
    @AppStorage("aichat_model_id") private var modelID = ""

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ollama Server URL")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("http://192.168.1.182:11434", text: $config.baseURL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .font(.system(.body, design: .monospaced))
                }
            } header: {
                Text("Connection")
            } footer: {
                Text("Enter the base URL of your Ollama server.")
            }

            Section {
                Button(action: fetchModels) {
                    HStack {
                        if isFetching {
                            ProgressView().padding(.trailing, 8)
                        }
                        Text(isFetching ? "Fetching Models..." : "Fetch Models")
                            .bold()
                    }
                }
                .disabled(isFetching || config.baseURL.isEmpty)

                if !diagnostics.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(diagnostics, id: \.self) { log in
                            Text(log)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption.bold())
                }
            }

            if !config.cachedModels.isEmpty {
                Section {
                    Picker("Selected Model", selection: $config.modelName) {
                        ForEach(config.cachedModels) { model in
                            Text(model.name).tag(model.id)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Available Models")
                }
            }

            Section {
                Button {
                    config.providerType = .ollama
                    config.name = "Ollama (\(config.modelName))"
                    AIChatSettingsManager.shared.settings.selectedLocalConfigID = config.id
                    AIChatSettingsManager.shared.settings.selectedProviderID = "local_models"
                    selectedProviderID = "local_models"
                    modelID = config.modelName
                    onComplete(config)
                } label: {
                    HStack {
                        Spacer()
                        Text("Save & Set Active")
                            .bold()
                        Spacer()
                    }
                }
                .disabled(config.modelName.isEmpty || isFetching)
            }
        }
        .navigationTitle("Ollama Setup")
    }

    private func fetchModels() {
        isFetching = true
        errorMessage = nil
        diagnostics = ["Starting discovery..."]

        Task {
            do {
                let normalized = OllamaConfig.normalizeEndpoint(config.baseURL)
                await MainActor.run { diagnostics.append("Normalized: \(normalized)") }

                let models = try await OllamaConfig.fetchModels(endpoint: normalized)
                await MainActor.run {
                    self.config.cachedModels = models
                    self.config.baseURL = normalized
                    if self.config.modelName.isEmpty || !models.contains(where: { $0.id == self.config.modelName }) {
                        self.config.modelName = models.first?.id ?? ""
                    }
                    self.diagnostics.append("Discovered \(models.count) models.")
                    self.isFetching = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.diagnostics.append("FAILED: \(error.localizedDescription)")
                    self.isFetching = false
                }
            }
        }
    }
}
