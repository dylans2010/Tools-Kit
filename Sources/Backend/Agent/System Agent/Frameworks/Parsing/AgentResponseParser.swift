import Foundation

struct AgentResponseParser {
    func parseFinalText(_ text: String) -> String {
        guard let data = text.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let final = object["final"] as? String else {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return final
    }
}
