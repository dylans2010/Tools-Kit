import Foundation

struct AgentToolResultCache {
    private var storage: [String: String] = [:]

    mutating func put(tool: String, result: String) { storage[tool] = result }
    func get(tool: String) -> String? { storage[tool] }
}
