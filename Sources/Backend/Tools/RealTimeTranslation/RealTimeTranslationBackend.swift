import Foundation

class RealTimeTranslationBackend: ObservableObject {
    @Published var inputText = ""
    @Published var translatedText = ""
    @Published var sourceLanguage = "en"
    @Published var targetLanguage = "fr"
    @Published var isTranslating = false

    let languages = ["en": "English", "fr": "French", "es": "Spanish", "de": "German", "it": "Italian", "pt": "Portuguese", "ru": "Russian", "zh": "Chinese", "ja": "Japanese", "ko": "Korean"]

    func translate() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            translatedText = ""
            return
        }

        isTranslating = true

        // Simulating functional translation feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.translatedText = "[Translated to \(self.languages[self.targetLanguage] ?? self.targetLanguage)]: " + text
            self.isTranslating = false
        }
    }
}
