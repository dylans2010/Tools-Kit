import SwiftUI

struct AvailableLocalModelsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var settingsManager = AIChatSettingsManager.shared
    @AppStorage("aichat_selected_provider") private var selectedProviderID = "openrouter"
    @AppStorage("aichat_model_id") private var modelID = ""

    @StateObject private var afmManager = AFMModelManager.shared
    @StateObject private var connectionManager = LMConnectionManager.shared

    var body: some View {
        NavigationStack {
            List {
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

                Section("LM Link Models") {
                    if connectionManager.availableModels.isEmpty {
                        Text("No LM Link models available.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(connectionManager.availableModels) { lmModel in
                            modelRow(AIModel(id: lmModel.id, name: lmModel.name), source: "lmstudio")
                        }
                    }
                }

                Section("Custom Providers") {
                    ForEach(settingsManager.settings.localConfigs) { config in
                        modelRow(AIModel(id: config.modelName, name: config.name), source: "local_models", configID: config.id)
                    }
                }
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
        settingsManager.settings.selectedProviderID = source
        selectedProviderID = source
        modelID = model.id
        settingsManager.settings.modelID = model.id

        if source == "afm" {
            settingsManager.settings.selectedAFMModelID = model.id
            settingsManager.settings.selectedLocalConfigID = nil
        } else if source == "local_models" {
            if let configID = configID {
                settingsManager.settings.selectedLocalConfigID = configID
            } else if let config = settingsManager.settings.localConfigs.first(where: { $0.modelName == model.id }) {
                settingsManager.settings.selectedLocalConfigID = config.id
            }
        } else if source == "lmstudio" {
            settingsManager.settings.selectedLocalConfigID = nil
        }

        dismiss()
    }
}
