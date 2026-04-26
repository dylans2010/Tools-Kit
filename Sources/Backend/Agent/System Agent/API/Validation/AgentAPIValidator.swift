import Foundation

struct AgentAPIValidator {
    init() {}

    func validateResponse(_ response: AgentAPIResponse) throws {
        if response.text.isEmpty && response.finishReason != "stop" {
            throw AgentValidationError.invalidFormat("text")
        }
    }
}
