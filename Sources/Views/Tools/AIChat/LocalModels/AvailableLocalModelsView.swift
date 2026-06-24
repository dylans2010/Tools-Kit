import SwiftUI

struct AvailableLocalModelsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var settingsManager = AIChatSettingsManager.shared
    @AppStorage("aichat_selected_provider") private var selectedProviderID = "openrouter"
    @AppStorage("aichat_model_id") private var modelID = ""

    @StateObject private var afmManager = AFMModelManager.shared
    @State private var downloadedModels: [AIModel] = []

    var body: some View {
        NavigationStack {
            List {
                Section("Downloaded HuggingFace Models") {
                    if downloadedModels.isEmpty {
                        Text("No models downloaded.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(downloadedModels) { model in
                            modelRow(model, source: "huggingface")
                        }
                    }

                    NavigationLink(destination: HFInstalledModels()) {
                        Label("Manage Downloads", systemImage: "folder.badge.gearshape")
                            .foregroundColor(.blue)
                    }
                }

                Section("Favorited Models") {
                    if settingsManager.settings.favoriteModels.isEmpty {
                        Text("No favorite models.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(settingsManager.settings.favoriteModels) { model in
                            modelRow(model, source: "local_models")
                        }
                    }
                }

                Section("Apple Foundation Models (AFM)") {
                    ForEach(afmManager.availableModels, id: \.self) { modelName in
                        modelRow(AIModel(id: modelName, name: modelName), source: "afm")
                    }
                }

                Section("Custom Providers") {
                    ForEach(settingsManager.settings.localConfigs) { config in
                        modelRow(AIModel(id: config.modelName, name: config.name), source: "local_models", configID: config.id)
                    }

                    NavigationLink(destination: SetupLocalModelsView()) {
                        Label("Add Custom Provider", systemImage: "plus.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                loadDownloadedModels()
            }
            .navigationTitle("Select Model")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func modelRow(_ model: AIModel, source: String, configID: UUID? = nil) -> some View {
        Button {
            selectModel(model, source: source, configID: configID)
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(model.name)
                        .font(.headline)
                    Text(model.id)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if modelID == model.id && selectedProviderID == source {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .foregroundColor(.primary)
    }

    private func selectModel(_ model: AIModel, source: String, configID: UUID?) {
        // Update both the binding/settings AND the AppStorage
        settingsManager.settings.selectedProviderID = source
        self.selectedProviderID = source

        self.modelID = model.id
        settingsManager.settings.modelID = model.id

        if source == "afm" {
            settingsManager.settings.selectedAFMModelID = model.id
            settingsManager.settings.selectedLocalConfigID = nil
        } else if source == "huggingface" {
            // HF models don't have a specific config ID yet, they use HFInferenceService
            settingsManager.settings.selectedLocalConfigID = nil
        } else if source == "local_models" {
            if let configID = configID {
                settingsManager.settings.selectedLocalConfigID = configID
            } else if let config = settingsManager.settings.localConfigs.first(where: { $0.modelName == model.id }) {
                settingsManager.settings.selectedLocalConfigID = config.id
            }
        }

        dismiss()
    }

    private func loadDownloadedModels() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let hfRootFolder = paths[0].appendingPathComponent("HuggingFace", isDirectory: true)

        guard let folders = try? FileManager.default.contentsOfDirectory(at: hfRootFolder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else {
            return
        }

        var models: [AIModel] = []
        for folder in folders {
            if folder.hasDirectoryPath {
                let modelID = folder.lastPathComponent.replacingOccurrences(of: "_", with: "/")
                // Try to find a GGUF file in the folder
                if let files = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil),
                   files.contains(where: { $0.pathExtension.lowercased() == "gguf" }) {
                    models.append(AIModel(id: modelID, name: modelID.components(separatedBy: "/").last ?? modelID))
                }
            }
        }
        self.downloadedModels = models
    }
}
