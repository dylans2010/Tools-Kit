import Foundation

public struct AgentResponseValidator {
    public init() {}

    public func validate(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
