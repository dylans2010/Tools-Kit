import Foundation

struct AgentRequestValidator {
    func validate(_ request: AgentAPIRequest) -> [String] {
        var errors: [String] = []
        if request.model.isEmpty { errors.append("Model is required") }
        if request.messages.isEmpty { errors.append("At least one message is required") }
        return errors
    }
}
