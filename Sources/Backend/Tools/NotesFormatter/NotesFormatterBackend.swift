import Foundation

enum NoteFormatStyle: String, CaseIterable, Sendable {
    case bulletPoints = "• Bullet Points"
    case numberedList = "1. Numbered List"
    case dashedList = "- Dashed List"
    case cleanEmptyLines = "Remove Empty Lines"
    case trimWhitespace = "Trim Whitespace"
}

class NotesFormatterBackend: ObservableObject {
    @Published var inputText = ""
    @Published var outputText = ""

    func format(to style: NoteFormatStyle) {
        let lines = inputText.components(separatedBy: .newlines)

        switch style {
        case .bulletPoints:
            outputText = lines.map { "• " + $0.trimmingCharacters(in: .whitespaces) }.joined(separator: "\n")
        case .numberedList:
            outputText = lines.enumerated().map { index, line in
                "\(index + 1). " + line.trimmingCharacters(in: .whitespaces)
            }.joined(separator: "\n")
        case .dashedList:
            outputText = lines.map { "- " + $0.trimmingCharacters(in: .whitespaces) }.joined(separator: "\n")
        case .cleanEmptyLines:
            outputText = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.joined(separator: "\n")
        case .trimWhitespace:
            outputText = lines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.joined(separator: "\n")
        }
    }
}
