import Foundation

struct AgentCapabilityValidator {
    func missing(required: AgentCapabilities, available: AgentCapabilities) -> AgentCapabilities {
        AgentCapabilities(rawValue: required.rawValue & ~available.rawValue)
    }

    func satisfies(required: AgentCapabilities, available: AgentCapabilities) -> Bool {
        missing(required: required, available: available).isEmpty
    }
}
