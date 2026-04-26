import Foundation

struct AgentLongTermMemory {
    private var storage: [String: String] = [:]

    mutating func remember(key: String, value: String) { storage[key] = value }
    func recall(key: String) -> String? { storage[key] }
    func all() -> [String: String] { storage }
}
