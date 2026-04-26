import Foundation

struct AgentModelRegistry {
    private(set) var models: Set<String> = []

    mutating func register(_ model: String) { models.insert(model) }
    func contains(_ model: String) -> Bool { models.contains(model) }
}
