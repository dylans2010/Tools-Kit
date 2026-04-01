import Foundation

class CodeFormatterBackend: ObservableObject {
    @Published var inputText = ""
    @Published var formattedText = ""
    @Published var selectedLanguage = "Swift"

    let languages = ["Swift", "HTML", "CSS", "JSON", "JavaScript"]

    func format() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        formattedText = "// Formatted \(selectedLanguage)\n" + trimmed
    }
}
