import Foundation

struct AgentCodeBlockParser {
    func parse(_ source: String) -> [AgentCodeBlock] {
        let pattern = "```(\w+)?\n([\s\S]*?)```"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        return regex.matches(in: source, range: range).compactMap { match in
            guard let codeRange = Range(match.range(at: 2), in: source) else { return nil }
            let langRange = Range(match.range(at: 1), in: source)
            let lang = langRange.map { String(source[$0]) } ?? "plaintext"
            return AgentCodeBlock(language: lang.isEmpty ? "plaintext" : lang, code: String(source[codeRange]))
        }
    }
}
