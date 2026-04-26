import Foundation

struct AgentResponseParser {
    init() {}

    func parseEnvelope(from content: String) -> (toolCall: (name: String, input: [String: Any])?, finalText: String?) {
        let cleaned = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return (nil, content)
        }

        if let tool = object["tool"] as? String {
            return ((tool, object["input"] as? [String: Any] ?? [:]), nil)
        }

        if let final = object["final"] as? String {
            return (nil, final)
        }

        return (nil, content)
    }
}
