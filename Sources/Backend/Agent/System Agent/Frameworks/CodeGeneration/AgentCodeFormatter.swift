import Foundation

struct AgentCodeFormatter {
    func normalizeWhitespace(_ code: String) -> String {
        code
            .split(separator: "
", omittingEmptySubsequences: false)
            .map { $0.replacingOccurrences(of: "	", with: "    ").trimmingCharacters(in: .whitespaces) }
            .joined(separator: "
")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
