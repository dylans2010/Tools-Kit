import Foundation

struct AgentAPIValidator: Sendable {
    init() {}

    func validateResponse(_ response: AgentAPIResponse) throws {
        if response.text.isEmpty && response.finishReason != "stop" {
            throw AgentValidationError.invalidFormat("text")
        }
    }
}
