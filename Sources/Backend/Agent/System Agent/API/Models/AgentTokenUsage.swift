import Foundation

public struct AgentTokenUsage: Codable {
    public let promptTokens: Int
    public let completionTokens: Int
    public let totalTokens: Int

    public init(promptTokens: Int, completionTokens: Int) {
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.totalTokens = promptTokens + completionTokens
    }
}
