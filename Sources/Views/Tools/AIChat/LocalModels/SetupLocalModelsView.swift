import SwiftUI

struct FetchLocalModelsFramework {
    static func fetchModels(from baseURL: String) async throws -> [AIModel] {
        guard let url = URL(string: "\(baseURL)/v1/models") else {
            throw AIError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AIError.invalidResponse
        }

        let decoder = JSONDecoder()
        // Try to decode as OpenAI format first
        if let openAIResponse = try? decoder.decode(OpenAIModelsResponse.self, from: data) {
            return openAIResponse.data.map { AIModel(id: $0.id, name: $0.id) }
        }

        // Try Ollama format
        if let ollamaResponse = try? decoder.decode(OllamaModelsResponse.self, from: data) {
            return ollamaResponse.models.map { AIModel(id: $0.name, name: $0.name) }
        }

        throw AIError.decodingFailed
    }

    struct OpenAIModelsResponse: Codable {
        let data: [OpenAIModelData]
    }

    struct OpenAIModelData: Codable {
        let id: String
    }

    struct OllamaModelsResponse: Codable {
        let models: [OllamaModelData]
    }

    struct OllamaModelData: Codable {
        let name: String
    }
}

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
    @State private var isFetching = false
    @State private var fetchError: String?

    var body: some View {
        Form {
            Section {
                TextField("Name (e.g. Ollama Home)", text: $config.name)
                TextField("Base URL", text: $config.baseURL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                TextField("Model Name", text: $config.modelName)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } header: {
                Text("Connection")
            }

            Section {
                Button(action: fetchModels) {
                    HStack {
                        if isFetching {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Text(isFetching ? "Fetching Models..." : "Fetch Available Models")
                            .bold()
                    }
                }
                .disabled(isFetching || config.baseURL.isEmpty)

                if let error = fetchError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                if !config.cachedModels.isEmpty {
                    Text("\(config.cachedModels.count) models cached")
                        .font(.caption2)
                        .foregroundColor(.secondary)
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
                        Text("Set as Active Model")
                            .bold()
                        Spacer()
                    }
                }
                .disabled(config.name.isEmpty || config.baseURL.isEmpty || config.modelName.isEmpty)
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

    private func fetchModels() {
        isFetching = true
        fetchError = nil

        Task {
            do {
                let models = try await FetchLocalModelsFramework.fetchModels(from: config.baseURL)
                await MainActor.run {
                    self.config.cachedModels = models
                    self.isFetching = false
                    onSave(config)
                }
            } catch {
                await MainActor.run {
                    self.fetchError = error.localizedDescription
                    self.isFetching = false
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
