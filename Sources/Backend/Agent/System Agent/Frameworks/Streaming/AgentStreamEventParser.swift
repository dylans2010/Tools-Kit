import Foundation

struct AgentStreamEventParser {
    func parseLines(from text: String) -> [String: String] {
        var event: [String: String] = [:]
        text.split(separator: "
").forEach { line in
            let parts = line.split(separator: ":", maxSplits: 1).map(String.init)
            if parts.count == 2 { event[parts[0].trimmingCharacters(in: .whitespaces)] = parts[1].trimmingCharacters(in: .whitespaces) }
        }
        return event
    }
}
