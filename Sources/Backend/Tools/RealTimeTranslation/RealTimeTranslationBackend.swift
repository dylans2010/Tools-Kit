import Foundation

class RealTimeTranslationBackend: ObservableObject {
    @Published var inputText = ""
    @Published var translatedText = ""
    @Published var sourceLanguage = "en"
    @Published var targetLanguage = "fr"

    let languages = ["en": "English", "fr": "French", "es": "Spanish", "de": "German", "it": "Italian", "pt": "Portuguese", "ru": "Russian", "zh": "Chinese", "ja": "Japanese", "ko": "Korean"]

    func translate() {
        if inputText.isEmpty {
            translatedText = ""
            return
        }
        translatedText = "[Translated to \(languages[targetLanguage] ?? targetLanguage)]: " + inputText
    }
}
