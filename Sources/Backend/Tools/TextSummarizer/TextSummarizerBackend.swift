import Foundation

class TextSummarizerBackend: ObservableObject {
    @Published var inputText = ""
    @Published var summaryText = ""
    @Published var isLoading = false

    func summarize() {
        guard !inputText.isEmpty else { return }
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isLoading = false
            let sentences = self.inputText.components(separatedBy: ".")
            if sentences.count > 2 {
                self.summaryText = sentences[0...1].joined(separator: ".") + "..."
            } else {
                self.summaryText = self.inputText
            }
        }
    }
}
