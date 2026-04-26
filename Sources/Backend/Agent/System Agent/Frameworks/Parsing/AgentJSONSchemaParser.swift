import Foundation

struct AgentJSONSchemaParser {
    init() {}

    func parse(schema: [String: Any]) -> [String: String] {
        // Extracts property names and types from a JSON schema
        guard let properties = schema["properties"] as? [String: [String: Any]] else { return [:] }
        return properties.reduce(into: [:]) { result, item in
            result[item.key] = item.value["type"] as? String ?? "unknown"
        }
    }
}
