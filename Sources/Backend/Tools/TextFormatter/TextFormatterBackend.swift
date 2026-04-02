import Foundation

enum TextCaseStyle: String, CaseIterable {
    case uppercase = "UPPERCASE"
    case lowercase = "lowercase"
    case capitalized = "Capitalized"
    case camelCase = "camelCase"
    case snakeCase = "snake_case"
    case kebabCase = "kebab-case"
    case titleCase = "Title Case"
}

class TextFormatterBackend: ObservableObject {
    @Published var inputText = ""
    @Published var outputText = ""

    func format(to style: TextCaseStyle) {
        let words = inputText.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }

        switch style {
        case .uppercase:
            outputText = inputText.uppercased()
        case .lowercase:
            outputText = inputText.lowercased()
        case .capitalized:
            outputText = inputText.capitalized
        case .camelCase:
            if words.isEmpty { outputText = ""; return }
            let first = words[0].lowercased()
            let remaining = words.dropFirst().map { $0.capitalized }
            outputText = first + remaining.joined()
        case .snakeCase:
            outputText = words.map { $0.lowercased() }.joined(separator: "_")
        case .kebabCase:
            outputText = words.map { $0.lowercased() }.joined(separator: "-")
        case .titleCase:
            outputText = words.map { $0.capitalized }.joined(separator: " ")
        }
    }
}
