import Foundation

public final class AgentCodeFormatter {
    public init() {}

    public func format(code: String, language: String) -> String {
        // Basic indentation formatter
        let lines = code.components(separatedBy: .newlines)
        var formatted = ""
        var indentLevel = 0

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            if trimmed.hasPrefix("}") || trimmed.hasPrefix("]") || trimmed.hasPrefix(")") {
                indentLevel = max(0, indentLevel - 1)
            }

            formatted += String(repeating: "    ", count: indentLevel) + trimmed + "\n"

            if trimmed.hasSuffix("{") || trimmed.hasSuffix("[") || trimmed.hasSuffix("(") {
                indentLevel += 1
            }
        }
        return formatted
    }
}
