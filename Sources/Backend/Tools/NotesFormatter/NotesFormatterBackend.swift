import Foundation

class NotesFormatterBackend: ObservableObject {
    @Published var inputText = ""
    @Published var formattedText = ""

    func format(to style: FormatStyle) {
        switch style {
        case .uppercase: formattedText = inputText.uppercased()
        case .lowercase: formattedText = inputText.lowercased()
        case .capitalized: formattedText = inputText.capitalized
        case .bulletPoints:
            formattedText = inputText.components(separatedBy: .newlines)
                .map { "• " + $0 }
                .joined(separator: "\n")
        }
    }

    enum FormatStyle {
        case uppercase, lowercase, capitalized, bulletPoints
    }
}
