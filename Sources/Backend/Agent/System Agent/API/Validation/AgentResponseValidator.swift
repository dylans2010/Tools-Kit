import Foundation

struct AgentResponseValidator {
    func validate(_ response: AgentAPIResponse) -> [String] {
        var errors: [String] = []
        if response.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { errors.append("Response text is empty") }
        if response.finishReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { errors.append("Missing finish reason") }
        return errors
    }
}
