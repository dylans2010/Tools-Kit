import Foundation

class RewriteEngine {
    func rewrite(text: String, style: RewriteStyle) -> String {
        guard !text.isEmpty else { return text }

        switch style {
        case .formal:
            return "Respected colleague, " + text
        case .casual:
            return "Hey, " + text.lowercased()
        case .friendly:
            return "Hope you're doing well! " + text
        case .direct:
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        case .concise:
            return text.components(separatedBy: .whitespacesAndNewlines).prefix(10).joined(separator: " ")
        case .persuasive:
            return "I strongly believe that " + text
        case .standard:
            return text
        }
    }

    func fixGrammar(text: String) -> String {
        // Logic for grammar correction
        return text.capitalized
    }
}
