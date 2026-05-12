import Foundation

struct AgentResponseValidator: Sendable {
    init() {}

    func validate(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
