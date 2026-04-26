import Foundation

struct AgentJSONSchemaParser {
    func requiredKeys(from schema: [String: Any]) -> [String] {
        (schema["required"] as? [String] ?? []).sorted()
    }
}
