import Foundation

public struct AgentConfiguration: Codable, Equatable {
    public var modelId: String
    public var temperature: Double
    public var maxTokens: Int?
    public var systemPromptOverride: String?
    public var enableStreaming: Bool

    public static var `default`: AgentConfiguration {
        AgentConfiguration(
            modelId: "gpt-4o",
            temperature: 0.7,
            maxTokens: 4096,
            systemPromptOverride: nil,
            enableStreaming: true
        )
    }
}
