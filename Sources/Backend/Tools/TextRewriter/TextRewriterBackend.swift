import Foundation

enum RewriteTone: String, CaseIterable {
    case professional = "Professional"
    case formal = "Formal"
    case casual = "Casual"
    case concise = "Concise"
}

class TextRewriterBackend: ObservableObject {
    @Published var inputText = ""
    @Published var rewrittenText = ""
    @Published var isProcessing = false

    private let professionalMap: [String: String] = [
        "get": "obtain",
        "buy": "purchase",
        "help": "assist",
        "fix": "resolve",
        "think": "believe",
        "check": "verify",
        "start": "commence",
        "end": "terminate",
        "use": "utilize",
        "want": "desire",
        "show": "demonstrate",
        "tell": "inform"
    ]

    private let formalMap: [String: String] = [
        "maybe": "perhaps",
        "really": "extremely",
        "bad": "unfavorable",
        "good": "commendable",
        "so": "consequently",
        "but": "however",
        "also": "furthermore",
        "kids": "children",
        "stuff": "materials",
        "anyways": "nevertheless"
    ]

    func rewrite(to tone: RewriteTone) {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isProcessing = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            var words = text.components(separatedBy: " ")
            let map: [String: String]

            switch tone {
            case .professional: map = self.professionalMap
            case .formal: map = self.formalMap
            case .casual:
                self.rewrittenText = "Hey! " + text.lowercased().replacingOccurrences(of: ".", with: "!")
                self.isProcessing = false
                return
            case .concise:
                self.rewrittenText = text.components(separatedBy: ".").first ?? text
                self.isProcessing = false
                return
            }

            for i in 0..<words.count {
                let cleanWord = words[i].lowercased().trimmingCharacters(in: .punctuationCharacters)
                if let replacement = map[cleanWord] {
                    let hasPunctuation = words[i].rangeOfCharacter(from: .punctuationCharacters) != nil
                    let punctuation = hasPunctuation ? String(words[i].suffix(1)) : ""
                    words[i] = (words[i].first?.isUppercase ?? false ? replacement.capitalized : replacement) + punctuation
                }
            }

            self.rewrittenText = words.joined(separator: " ")
            self.isProcessing = false
        }
    }
}
