import Foundation

struct AgentResponseValidator {
    init() {}

    func validate(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
