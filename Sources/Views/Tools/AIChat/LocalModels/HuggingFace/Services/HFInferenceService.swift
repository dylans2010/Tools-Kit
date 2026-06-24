import Foundation

@MainActor
class HFInferenceService: ObservableObject {
    static let shared = HFInferenceService()

    func sendRequest(messages: [ChatMessage], modelID: String) async throws -> String {
        // This is a bridge to a local LLM runner that can load GGUF files.
        // For now, we'll try to find if there's a local server running that can handle this model,
        // or we use a placeholder that explains how to run it.

        SDKLogStore.shared.log("HFInferenceService: Attempting to run model \(modelID)", source: "HFInferenceService", level: .info)

        // In a real implementation, this would interface with a library like llama.cpp via a wrapper
        // or talk to a local service that manages these models.

        // Since we are redefining the service, we should at least try to talk to a common local endpoint
        // if the user has one set up, or throw a descriptive error.

        let settings = AIChatSettingsManager.shared.settings
        if let configID = settings.selectedLocalConfigID,
           let config = settings.localConfigs.first(where: { $0.id == configID }) {
            // Bridge to the selected local config but override the model name with the HF model ID
            var bridgedConfig = config
            bridgedConfig.modelName = modelID

            return try await AIService.AILocalService.shared.sendRequest(messages: messages, config: bridgedConfig)
        }

        throw NSError(domain: "HFInferenceService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No local runner configured to execute HuggingFace model: \(modelID). Please set up a Custom Provider in Local Model settings."])
    }
}
