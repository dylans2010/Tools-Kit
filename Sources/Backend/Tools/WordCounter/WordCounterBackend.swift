import Foundation
class WordCounterBackend: ObservableObject {
    @Published var text = ""
    var wordCount: Int { text.split { $0.isWhitespace }.count }
}
