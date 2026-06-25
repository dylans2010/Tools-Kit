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

    var body: some View {
        Form {
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
