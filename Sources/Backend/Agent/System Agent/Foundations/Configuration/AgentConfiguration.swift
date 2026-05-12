import Foundation

struct AgentConfiguration: Codable, Equatable, Sendable {
    var modelId: String
    var temperature: Double
    var maxTokens: Int?
    var systemPromptOverride: String?
    var enableStreaming: Bool

    static var `default`: AgentConfiguration {
        AgentConfiguration(
            modelId: "gpt-4o",
            temperature: 0.7,
            maxTokens: 4096,
            systemPromptOverride: nil,
            enableStreaming: true
        )
    }
}
