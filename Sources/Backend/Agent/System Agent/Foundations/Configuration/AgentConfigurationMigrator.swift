import Foundation

struct AgentConfigurationMigrator: Sendable {
    init() {}

    func migrate(_ data: [String: Any]) -> AgentConfiguration {
        var config = AgentConfiguration.default

        if let modelId = data["modelId"] as? String {
            config.modelId = modelId
        }
        if let temperature = data["temperature"] as? Double {
            config.temperature = temperature
        }
        if let maxTokens = data["maxTokens"] as? Int {
            config.maxTokens = maxTokens
        }
        if let systemPromptOverride = data["systemPromptOverride"] as? String {
            config.systemPromptOverride = systemPromptOverride
        }
        if let enableStreaming = data["enableStreaming"] as? Bool {
            config.enableStreaming = enableStreaming
        }

        return config
    }
}
