import Foundation

struct AgentCodeBlockParser: Sendable {
    init() {}

    func parse(text: String) -> [AgentCodeBlock] {
        let pattern = #"```(\w*)\n([\s\S]*?)```"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, options: [], range: range)

        return matches.compactMap { match in
            guard let langRange = Range(match.range(at: 1), in: text),
                  let codeRange = Range(match.range(at: 2), in: text) else { return nil }
            return AgentCodeBlock(language: String(text[langRange]), code: String(text[codeRange]))
        }
    }
}
