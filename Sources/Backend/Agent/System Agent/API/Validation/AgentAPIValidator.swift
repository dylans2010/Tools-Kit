import Foundation

public struct AgentAPIValidator {
    public init() {}

    public func validateResponse(_ response: AgentAPIResponse) throws {
        if response.text.isEmpty && response.finishReason != "stop" {
            throw AgentValidationError.invalidFormat("text")
        }
    }
}
