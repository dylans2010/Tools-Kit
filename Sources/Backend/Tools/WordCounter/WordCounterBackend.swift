import Foundation

class WordCounterBackend: ObservableObject {
    @Published var text = ""

    var characterCount: Int { text.count }
    var wordCount: Int { text.split { $0.isWhitespace || $0.isNewline }.count }
    var lineCount: Int { text.components(separatedBy: .newlines).count }
    var sentenceCount: Int {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        return sentences.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }
}
