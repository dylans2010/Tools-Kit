import SwiftUI

struct SetupLocalModelsView: View {
    @ObservedObject var settingsManager = AIChatSettingsManager.shared
    @AppStorage("aichat_model_id") private var modelID = ""
    @State private var showingAddSheet = false
    @State private var showingDefaultSheet = false
    @State private var configToEdit: LocalModelConfig?

    var body: some View {
        List {
            Section {
                Button {
                    showingDefaultSheet = true
                } label: {
                    HStack {
                        Label("Set Default Model", systemImage: "star.fill")
                            .font(.headline)
                        Spacer()
                        Text(modelID.isEmpty ? "None" : modelID)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                SectionHeader(title: "Primary Model", subtitle: "Configure your default local AI", icon: "sparkles")
                    .listRowInsets(EdgeInsets())
                    .padding(.bottom, 8)
            }

            Section {
                if settingsManager.settings.localConfigs.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "server.rack")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No local model configurations found.")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else {
                    ForEach(settingsManager.settings.localConfigs) { config in
                        configRow(config)
                    }
                    .onDelete(perform: deleteConfigs)
                }
            } header: {
                SectionHeader(title: "Environments", subtitle: "Manage your manual local setups", icon: "server.rack")
                    .listRowInsets(EdgeInsets())
                    .padding(.bottom, 8)
            }

            Section {
                NavigationLink(destination: LMLinkMainView()) {
                    Label("LM Studio (LM Link)", systemImage: "link.badge.plus")
                        .font(.headline)
                }

                NavigationLink(destination: AFMMainView()) {
                    Label("Apple Foundation Models", systemImage: "apple.logo")
                        .font(.headline)
                }
            } header: {
                SectionHeader(title: "Unified Local AI", subtitle: "Connect to LM Studio or native AFM", icon: "sparkles")
                    .listRowInsets(EdgeInsets())
                    .padding(.bottom, 8)
            }

            Section {
                Button {
                    configToEdit = LocalModelConfig()
                    showingAddSheet = true
                } label: {
                    Label("Add Manual Local Model", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
                .padding(.vertical, 4)
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
        .sheet(isPresented: $showingDefaultSheet) {
            LocalModelsByDefault()
        }
    }

    private func configRow(_ config: LocalModelConfig) -> some View {
        Button {
            configToEdit = config
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(settingsManager.settings.selectedLocalConfigID == config.id ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: "desktopcomputer")
                        .foregroundColor(settingsManager.settings.selectedLocalConfigID == config.id ? .blue : .primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(config.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(config.baseURL)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if settingsManager.settings.selectedLocalConfigID == config.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
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
            settingsManager.settings.selectedProviderID = "local_models"
        }
    }

    private func deleteConfigs(at offsets: IndexSet) {
        settingsManager.settings.localConfigs.remove(atOffsets: offsets)
        if let selectedID = settingsManager.settings.selectedLocalConfigID,
           !settingsManager.settings.localConfigs.contains(where: { $0.id == selectedID }) {
            settingsManager.settings.selectedLocalConfigID = settingsManager.settings.localConfigs.first?.id
            if settingsManager.settings.selectedLocalConfigID == nil && settingsManager.settings.selectedProviderID == "local_models" {
                settingsManager.settings.selectedProviderID = "openrouter" // Fallback
            }
        }
    }
}

struct LocalModelsByDefault: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var settingsManager = AIChatSettingsManager.shared
    @AppStorage("aichat_selected_provider") private var selectedProviderID = "openrouter"
    @AppStorage("aichat_model_id") private var modelID = ""
    @StateObject private var afmManager = AFMModelManager.shared
    @StateObject private var lmConnection = LMConnectionManager.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(settingsManager.settings.localConfigs) { config in
                        Button {
                            selectManualModel(config)
                        } label: {
                            HStack {
                                Label(config.name, systemImage: "desktopcomputer")
                                Spacer()
                                Text(config.modelName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if settingsManager.settings.selectedLocalConfigID == config.id && selectedProviderID == "local_models" {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                } header: {
                    Text("Manual Local Models")
                }

                Section {
                    ForEach(afmManager.availableModels, id: \.self) { model in
                        Button {
                            selectAFMModel(model)
                        } label: {
                            HStack {
                                Label(model, systemImage: "apple.logo")
                                Spacer()
                                if settingsManager.settings.selectedAFMModelID == model && selectedProviderID == "afm" {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                } header: {
                    Text("Apple Foundation Models")
                }

                Section {
                    if let device = lmConnection.selectedDevice {
                        ForEach(device.models) { model in
                            Button {
                                selectLMStudioModel(model, device: device)
                            } label: {
                                HStack {
                                    Label(model.name, systemImage: "link")
                                    Spacer()
                                    if modelID == model.id && selectedProviderID == "lmstudio" {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    } else {
                        Text("No LM Studio device selected.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("LM Studio (via \(lmConnection.selectedDevice?.name ?? "No Device")")
                }
            }
            .navigationTitle("Default Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                Task {
                    await lmConnection.fetchModelsForSelectedDevice()
                }
            }
        }
    }

    private func selectManualModel(_ config: LocalModelConfig) {
        selectedProviderID = "local_models"
        settingsManager.settings.selectedProviderID = "local_models"
        settingsManager.settings.selectedLocalConfigID = config.id
        modelID = config.modelName
        settingsManager.settings.modelID = config.modelName
        dismiss()
    }

    private func selectAFMModel(_ modelID: String) {
        selectedProviderID = "afm"
        settingsManager.settings.selectedProviderID = "afm"
        settingsManager.settings.selectedAFMModelID = modelID
        self.modelID = modelID
        settingsManager.settings.modelID = modelID
        dismiss()
    }

    private func selectLMStudioModel(_ model: LMModel, device: LMDevice) {
        selectedProviderID = "lmstudio"
        settingsManager.settings.selectedProviderID = "lmstudio"
        modelID = model.id
        settingsManager.settings.modelID = model.id
        lmConnection.selectDevice(device)
        lmConnection.selectModel(model)
        dismiss()
    }
}

struct EditLocalModelConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("aichat_selected_provider") private var selectedProviderID = "openrouter"
    @State var config: LocalModelConfig
    var onSave: (LocalModelConfig) -> Void

    @State private var testingConnection = false
    @State private var testResult: Result<String, Error>?
    @State private var newHeaderKey = ""
    @State private var newHeaderValue = ""
    @State private var newStopSequence = ""
    @State private var showingAdvanced = false

    var body: some View {
        Form {
            Group {
                Section {
                    settingRow(icon: "tag.fill", label: "Name") {
                        TextField("Configuration Name", text: $config.name)
                    }
                    settingRow(icon: "link", label: "Base URL") {
                        TextField("http://localhost:11434/v1", text: $config.baseURL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    settingRow(icon: "cpu", label: "Model") {
                        TextField("llama3", text: $config.modelName)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    settingRow(icon: "key.fill", label: "API Key") {
                        SecureField("Optional", text: $config.apiKey)
                    }
                    settingRow(icon: "timer", label: "Timeout") {
                        Stepper("\(Int(config.timeout))s", value: $config.timeout, in: 5...600, step: 5)
                    }
                } header: {
                    SectionHeader(title: "General", subtitle: "Basic connection settings", icon: "gearshape.fill")
                        .listRowInsets(EdgeInsets())
                }

                Section {
                    settingSlider(label: "Temperature", value: Binding(
                        get: { config.temperature },
                        set: { config.temperature = max(0, min(2, $0)) }
                    ), range: 0...2, step: 0.1, icon: "thermometer.medium", specifier: "%.1f")

                    settingRow(icon: "text.quote", label: "Max Tokens") {
                        Stepper("\(config.maxTokens)", value: Binding(
                            get: { config.maxTokens },
                            set: { config.maxTokens = max(128, min(128000, $0)) }
                        ), in: 128...128000, step: 128)
                    }

                    Toggle(isOn: $config.isStreamingEnabled) {
                        Label("Enable Streaming", systemImage: "antenna.radiowaves.left.and.right")
                    }

                    Button {
                        showingAdvanced = true
                    } label: {
                        Label("Advanced Parameters", systemImage: "slider.horizontal.3")
                            .foregroundColor(.blue)
                    }
                } header: {
                    SectionHeader(title: "Core Parameters", subtitle: "Inference engine behavior", icon: "slider.horizontal.3")
                        .listRowInsets(EdgeInsets())
                }

                Section {
                    settingRow(icon: "list.bullet.indent", label: "Logprobs") {
                        Stepper("\(config.logprobs)", value: $config.logprobs, in: 0...20, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Stop Sequences", systemImage: "hand.raised.fill")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)

                        FlowLayout(config.stopSequences, spacing: 8) { seq in
                            HStack(spacing: 4) {
                                Text(seq).font(.caption)
                                Button {
                                    config.stopSequences.removeAll { $0 == seq }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption2)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }

                        HStack {
                            TextField("Add stop sequence...", text: $newStopSequence)
                                .textFieldStyle(.roundedBorder)
                                .font(.caption)
                            Button {
                                guard !newStopSequence.isEmpty else { return }
                                config.stopSequences.append(newStopSequence)
                                newStopSequence = ""
                            } label: {
                                Image(systemName: "plus.circle.fill")
                            }
                            .disabled(newStopSequence.isEmpty)
                        }
                    }
                } header: {
                    SectionHeader(title: "Interaction", subtitle: "Response formatting", icon: "bubble.left.and.bubble.right")
                        .listRowInsets(EdgeInsets())
                }

                Section {
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
                } header: {
                    SectionHeader(title: "Custom Headers", subtitle: "Additional HTTP headers", icon: "line.3.horizontal.decrease.circle")
                        .listRowInsets(EdgeInsets())
                }

                Section {
                    Button {
                        testConnection()
                    } label: {
                        HStack {
                            if testingConnection {
                                ProgressView().padding(.trailing, 8)
                            }
                            Label("Run Connection Audit", systemImage: "network")
                                .bold()
                        }
                    }
                    .disabled(testingConnection || config.baseURL.isEmpty)

                    if let result = testResult {
                        switch result {
                        case .success(let message):
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                Text(message)
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(10)
                        case .failure(let error):
                            HStack(alignment: .top) {
                                Image(systemName: "exclamationmark.octagon.fill")
                                    .foregroundColor(.red)
                                Text(error.localizedDescription)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                } header: {
                    SectionHeader(title: "Diagnostics", subtitle: "Verify server availability", icon: "waveform.path.ecg")
                        .listRowInsets(EdgeInsets())
                }

                Section {
                    Button {
                        AIChatSettingsManager.shared.settings.selectedLocalConfigID = config.id
                        selectedProviderID = "local_models"
                        AIChatSettingsManager.shared.settings.selectedProviderID = "local_models"
                    } label: {
                        HStack {
                            Spacer()
                            if AIChatSettingsManager.shared.settings.selectedLocalConfigID == config.id &&
                               selectedProviderID == "local_models" {
                                Label("Currently Default Environment", systemImage: "star.fill")
                                    .foregroundColor(.orange)
                                    .bold()
                            } else {
                                Text("Set as Default Environment")
                                    .bold()
                                    .foregroundColor(.blue)
                            }
                            Spacer()
                        }
                    }
                    .disabled(config.name.isEmpty || config.baseURL.isEmpty || config.modelName.isEmpty)
                }
            }
        }
        .navigationTitle(config.name.isEmpty ? "New Environment" : config.name)
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
                .bold()
            }
        }
    }

    private func settingRow<Content: View>(icon: String, label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(.blue).frame(width: 24)
            Text(label)
            Spacer()
            content()
        }
    }

    private func settingSlider(label: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, icon: String, specifier: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon).foregroundColor(.blue).frame(width: 24)
                Text("\(label): \(value.wrappedValue, specifier: specifier)")
                Spacer()
            }
            Slider(value: value, in: range, step: step)
        }
    }

    private func testConnection() {
        testingConnection = true
        testResult = nil

        Task {
            do {
                // Determine test endpoint
                let isV1 = config.baseURL.contains("/v1")
                let testPath = isV1 ? "/models" : "/api/tags"

                var cleanBase = config.baseURL
                    .replacingOccurrences(of: "/chat/completions", with: "")

                if isV1 {
                    cleanBase = cleanBase.replacingOccurrences(of: "/v1", with: "")
                }

                let urlString = cleanBase + (isV1 ? "/v1" : "") + testPath
                guard let url = URL(string: urlString) else {
                    throw NSError(domain: "LocalModels", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Test URL: \(urlString)"])
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
                    self.testResult = .success("Connection successful! Server is reachable and responded.")
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

struct AdvancedLocalModelsConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var config: LocalModelConfig

    var body: some View {
        Form {
            Section {
                settingSlider(label: "Top-P", value: $config.topP, range: 0...1, step: 0.05, icon: "target", specifier: "%.2f")
                settingSlider(label: "Frequency Penalty", value: $config.frequencyPenalty, range: -2...2, step: 0.1, icon: "wave.3.right", specifier: "%.1f")
                settingSlider(label: "Presence Penalty", value: $config.presencePenalty, range: -2...2, step: 0.1, icon: "person.fill.viewfinder", specifier: "%.1f")
            } header: {
                SectionHeader(title: "Sampling", subtitle: "Fine-tune token selection", icon: "opticaldisc")
                    .listRowInsets(EdgeInsets())
            }

            Section {
                settingRow(icon: "number", label: "Seed") {
                    TextField("0", value: $config.seed, formatter: NumberFormatter())
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                }

                settingRow(icon: "list.number", label: "Top-K") {
                    Stepper("\(config.topK)", value: $config.topK, in: 0...100, step: 1)
                }

                settingSlider(label: "Min-P", value: $config.minP, range: 0...1, step: 0.01, icon: "arrow.down.to.line", specifier: "%.2f")
                settingSlider(label: "Typical-P", value: $config.typicalP, range: 0...1, step: 0.05, icon: "chart.line.uptrend.xyaxis", specifier: "%.2f")
                settingSlider(label: "TFS-Z", value: $config.tfsZ, range: 0...2, step: 0.05, icon: "skew", specifier: "%.2f")
            } header: {
                SectionHeader(title: "Advanced Sampling", subtitle: "Precision control", icon: "cpu")
                    .listRowInsets(EdgeInsets())
            }

            Section {
                settingSlider(label: "Repeat Penalty", value: $config.repeatPenalty, range: 0...2, step: 0.05, icon: "repeat.circle", specifier: "%.2f")
                settingRow(icon: "clock.arrow.circlepath", label: "Last N") {
                    Stepper("\(config.repeatLastN)", value: $config.repeatLastN, in: 0...2048, step: 8)
                }
            } header: {
                SectionHeader(title: "Repetition", subtitle: "Prevent loop behaviors", icon: "repeat")
                    .listRowInsets(EdgeInsets())
            }

            Section {
                settingRow(icon: "memorychip", label: "Batch Size") {
                    Stepper("\(config.batchSize)", value: $config.batchSize, in: 1...4096, step: 64)
                }
                settingRow(icon: "arrow.left.and.right.square", label: "Context") {
                    Stepper("\(config.contextLength)", value: $config.contextLength, in: 512...128000, step: 512)
                }
                settingRow(icon: "bolt.fill", label: "GPU Layers") {
                    Stepper("\(config.numGpu)", value: $config.numGpu, in: 0...128, step: 1)
                }
            } header: {
                SectionHeader(title: "Performance", subtitle: "Resource allocation", icon: "bolt.fill")
                    .listRowInsets(EdgeInsets())
            }
        }
        .navigationTitle("Advanced Settings")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func settingRow<Content: View>(icon: String, label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(.blue).frame(width: 24)
            Text(label)
            Spacer()
            content()
        }
    }

    private func settingSlider(label: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, icon: String, specifier: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon).foregroundColor(.blue).frame(width: 24)
                Text("\(label): \(value.wrappedValue, specifier: specifier)")
                Spacer()
            }
            Slider(value: value, in: range, step: step)
        }
    }
}
