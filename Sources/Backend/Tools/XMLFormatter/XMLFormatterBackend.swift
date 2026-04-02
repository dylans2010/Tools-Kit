import Foundation

class XMLFormatterBackend: ObservableObject {
    @Published var inputText = ""
    @Published var outputText = ""
    @Published var error = ""

    func format() {
        error = ""
        let xml = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !xml.isEmpty else {
            outputText = ""
            return
        }

        var indentLevel = 0
        let indentString = "    "
        var formatted = ""

        let tokens = tokenize(xml)

        for token in tokens {
            if token.hasPrefix("</") {
                indentLevel = max(0, indentLevel - 1)
                formatted += String(repeating: indentString, count: indentLevel) + token + "\n"
            } else if token.hasPrefix("<") && !token.hasSuffix("/>") && !token.hasPrefix("<?") && !token.hasPrefix("<!") {
                formatted += String(repeating: indentString, count: indentLevel) + token + "\n"
                indentLevel += 1
            } else {
                formatted += String(repeating: indentString, count: indentLevel) + token + "\n"
            }
        }

        outputText = formatted.trimmingCharacters(in: .newlines)
    }

    private func tokenize(_ xml: String) -> [String] {
        var tokens: [String] = []
        var currentToken = ""
        var insideTag = false

        for char in xml {
            if char == "<" {
                if !currentToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    tokens.append(currentToken.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                currentToken = "<"
                insideTag = true
            } else if char == ">" {
                currentToken.append(char)
                tokens.append(currentToken)
                currentToken = ""
                insideTag = false
            } else {
                currentToken.append(char)
            }
        }

        return tokens
    }
}
