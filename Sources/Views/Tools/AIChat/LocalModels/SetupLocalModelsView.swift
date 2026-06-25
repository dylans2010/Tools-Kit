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
                        NavigationLink(destination: LocalModelDetailsView(model: model, config: activeConfig ?? LocalModelConfig(), localService: AIService.AILocalService.shared)) {
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

// MARK: - Ollama Config (Redesign)

struct OllamaConfig {
    struct ValidationResult {
        let success: Bool
        let models: [AIModel]
        let version: String?
        let error: String?
        let diagnostics: [String]
    }

    static func normalizeEndpoint(_ input: String) -> String {
        var url = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if !url.starts(with: "http") {
            url = "http://\(url)"
        }
        if url.hasSuffix("/") {
            url = String(url.dropLast())
        }
        // If it contains /v1, remove it as we want the root for Ollama native APIs
        if url.contains("/v1") {
            url = url.replacingOccurrences(of: "/v1", with: "")
        }
        return url
    }

    static func testConnection(endpoint: String) async -> ValidationResult {
        var diagnostics: [String] = ["Probing Ollama server: \(endpoint)"]
        let baseURL = normalizeEndpoint(endpoint)

        // 1. Check version/root
        do {
            diagnostics.append("GET /")
            guard let url = URL(string: baseURL) else { throw AIError.invalidEndpoint }
            let (_, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse {
                diagnostics.append("Server responded with status \(http.statusCode)")
            }
        } catch {
            diagnostics.append("Root probe failed: \(error.localizedDescription)")
        }

        // 2. Fetch models
        do {
            diagnostics.append("Fetching models from /api/tags...")
            let models = try await fetchModels(endpoint: baseURL)
            diagnostics.append("Successfully discovered \(models.count) models.")
            return ValidationResult(success: true, models: models, version: nil, error: nil, diagnostics: diagnostics)
        } catch {
            diagnostics.append("Model discovery failed: \(error.localizedDescription)")
            return ValidationResult(success: false, models: [], version: nil, error: error.localizedDescription, diagnostics: diagnostics)
        }
    }

    static func fetchModels(endpoint: String) async throws -> [AIModel] {
        let baseURL = normalizeEndpoint(endpoint)
        guard let url = URL(string: "\(baseURL)/api/tags") else {
            throw AIError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AIError.invalidResponse
        }

        let decoder = JSONDecoder()
        do {
            let result = try decoder.decode(OllamaTagsResponse.self, from: data)
            return result.models.map { m in
                AIModel(id: m.name, name: m.name, supportsVision: m.name.contains("llava") || m.name.contains("vision"))
            }
        } catch {
            throw AIError.decodingFailed
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

        var body: [String: Any] = [:]
        body["model"] = model
        body["messages"] = messages.map { ["role": $0.role, "content": $0.content] }
        body["stream"] = false

        // Map options
        var options: [String: Any] = [:]
        if let temp = parameters["temperature"] as? Double { options["temperature"] = temp }
        if let topP = parameters["top_p"] as? Double { options["top_p"] = topP }
        if let seed = parameters["seed"] as? Int { options["seed"] = seed }
        if let repeatPenalty = parameters["repeat_penalty"] as? Double { options["repeat_penalty"] = repeatPenalty }
        if let numThread = parameters["num_thread"] as? Int { options["num_thread"] = numThread }

        if !options.isEmpty {
            body["options"] = options
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIError.requestFailed("Ollama returned status \(status): \(errorMsg)")
        }

        do {
            let result = try JSONDecoder().decode(OllamaChatResponse.self, from: data)
            return result.message.content
        } catch {
            throw AIError.decodingFailed
        }
    }

    static func sendGenerate(endpoint: String, model: String, prompt: String, parameters: [String: Any] = [:]) async throws -> String {
        let baseURL = normalizeEndpoint(endpoint)
        guard let url = URL(string: "\(baseURL)/api/generate") else {
            throw AIError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [:]
        body["model"] = model
        body["prompt"] = prompt
        body["stream"] = false

        var options: [String: Any] = [:]
        if let temp = parameters["temperature"] as? Double { options["temperature"] = temp }
        if !options.isEmpty { body["options"] = options }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AIError.requestFailed("Ollama /api/generate failed")
        }

        let result = try JSONDecoder().decode(OllamaGenerateResponse.self, from: data)
        return result.response
    }
}

private struct OllamaTagsResponse: Codable {
    let models: [OllamaTagModel]
}

private struct OllamaTagModel: Codable {
    let name: String
}

private struct OllamaChatResponse: Codable {
    struct Message: Codable {
        let role: String
        let content: String
    }
    let model: String
    let message: Message
    let done: Bool
}

private struct OllamaGenerateResponse: Codable {
    let model: String
    let response: String
    let done: Bool
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
    @State private var showingConnectView = false

    var body: some View {
        Form {
            Section {
                Button {
                    showingConnectView = true
                } label: {
                    Label("Connect to Mac Running Ollama", systemImage: "desktopcomputer")
                        .foregroundColor(.blue)
                        .bold()
                }
            }

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
                Text("Manual Connection")
            } footer: {
                Text("Enter the base URL of your Ollama server.")
            }

            Section {
                Button(action: fetchModels) {
                    HStack {
                        if isFetching {
                            ProgressView().padding(.trailing, 8)
                        }
                        Text(isFetching ? "Validating Ollama..." : "Fetch Models")
                            .bold()
                    }
                }
                .disabled(isFetching || config.baseURL.isEmpty)

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
        .sheet(isPresented: $showingConnectView) {
            NavigationStack {
                OllamaConnectView(config: $config) {
                    fetchModels()
                }
            }
        }
    }

    private func fetchModels() {
        isFetching = true
        errorMessage = nil
        diagnostics = ["Starting discovery..."]

        Task {
            let result = await OllamaConfig.testConnection(endpoint: config.baseURL)

            await MainActor.run {
                self.isFetching = false
                self.diagnostics = result.diagnostics
                if result.success {
                    self.config.cachedModels = result.models
                    self.config.baseURL = OllamaConfig.normalizeEndpoint(config.baseURL)
                    if self.config.modelName.isEmpty || !result.models.contains(where: { $0.id == self.config.modelName }) {
                        self.config.modelName = result.models.first?.id ?? ""
                    }
                } else {
                    self.errorMessage = result.error
                }
            }
        }
    }
}

// MARK: - WiFi Discovery (OllamaConnectConfig)

struct OllamaDiscoveredServer: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let host: String
    let port: Int

    var baseURL: String {
        let cleanedHost = host.hasSuffix(".") ? String(host.dropLast()) : host
        return "http://\(cleanedHost):\(port)"
    }
}

final class OllamaConnectConfig: NSObject, ObservableObject {
    @Published var discoveredServers: [OllamaDiscoveredServer] = []
    @Published var isSearching = false

    private var browser: NetServiceBrowser?
    private var services: Set<NetService> = []

    func startDiscovery() {
        stopDiscovery()
        isSearching = true
        discoveredServers.removeAll()
        services.removeAll()

        browser = NetServiceBrowser()
        browser?.delegate = self
        // Look for common HTTP services as Ollama doesn't always advertise specifically
        // But we'll try to probe them.
        browser?.searchForServices(ofType: "_http._tcp.", inDomain: "local.")
    }

    func stopDiscovery() {
        browser?.stop()
        browser = nil
        for service in services {
            service.stop()
        }
        services.removeAll()
        isSearching = false
    }

    private func updateDiscoveredServers() {
        DispatchQueue.main.async {
            self.discoveredServers = self.services.compactMap { service in
                guard let host = service.hostName, service.port != -1 else { return nil }
                return OllamaDiscoveredServer(
                    name: service.name,
                    host: host,
                    port: service.port
                )
            }
        }
    }
}

extension OllamaConnectConfig: NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        services.insert(service)
        service.delegate = self
        service.resolve(withTimeout: 5.0)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        services.remove(service)
        updateDiscoveredServers()
    }
}

extension OllamaConnectConfig: NetServiceDelegate {
    func netServiceDidResolveAddress(_ sender: NetService) {
        updateDiscoveredServers()
    }
}

// MARK: - OllamaConnectView

struct OllamaConnectView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var config: LocalModelConfig
    var onSelected: () -> Void

    @StateObject private var connector = OllamaConnectConfig()
    @State private var validatingID: UUID?

    var body: some View {
        List {
            Section {
                if connector.discoveredServers.isEmpty {
                    VStack(spacing: 12) {
                        if connector.isSearching {
                            ProgressView()
                            Text("Searching for Macs on your network...")
                                .foregroundColor(.secondary)
                        } else {
                            Text("No servers found.")
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ForEach(connector.discoveredServers) { server in
                        Button {
                            selectServer(server)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(server.name)
                                        .font(.headline)
                                    Text(server.baseURL)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if validatingID == server.id {
                                    ProgressView()
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("Discovered Servers")
            } footer: {
                Text("Make sure Ollama is running on your Mac and 'OLLAMA_HOST=0.0.0.0' is set if connecting from another device.")
            }

            Section {
                Button("Refresh") {
                    connector.startDiscovery()
                }
                .disabled(connector.isSearching)
            }
        }
        .navigationTitle("Connect to Mac")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .onAppear {
            connector.startDiscovery()
        }
        .onDisappear {
            connector.stopDiscovery()
        }
    }

    private func selectServer(_ server: OllamaDiscoveredServer) {
        validatingID = server.id
        Task {
            let result = await OllamaConfig.testConnection(endpoint: server.baseURL)
            await MainActor.run {
                validatingID = nil
                if result.success {
                    config.baseURL = server.baseURL
                    onSelected()
                    dismiss()
                }
            }
        }
    }
}
