import Foundation

struct AgentToolCallParser {
    func parse(_ text: String) -> (name: String, input: [String: String])? {
        guard let data = text.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let name = object["tool"] as? String else { return nil }
        let rawInput = object["input"] as? [String: Any] ?? [:]
        return (name, rawInput.mapValues { String(describing: $0) })
    }
}
