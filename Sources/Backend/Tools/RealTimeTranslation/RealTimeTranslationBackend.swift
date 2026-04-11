import Foundation

class RealTimeTranslationBackend: ObservableObject {
    @Published var inputText = ""
    @Published var translatedText = ""
    @Published var sourceLanguage = "en"
    @Published var targetLanguage = "fr"
    @Published var isTranslating = false

    let languages = ["en": "English", "fr": "French", "es": "Spanish", "de": "German", "it": "Italian", "pt": "Portuguese", "ru": "Russian", "zh": "Chinese", "ja": "Japanese", "ko": "Korean"]

    private let aiService = AIService()
    private var translationTask: Task<Void, Never>?

    func translate() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            translatedText = ""
            return
        }

        translationTask?.cancel()
        isTranslating = true

        translationTask = Task {
            do {
                let from = languages[sourceLanguage] ?? sourceLanguage
                let to = languages[targetLanguage] ?? targetLanguage
                let prompt = "Translate the following text from \(from) to \(to). Only return the translated text:\n\n\(text)"

                let result = try await aiService.processText(prompt: prompt, systemPrompt: "You are a professional translator.")

                if !Task.isCancelled {
                    DispatchQueue.main.async {
                        self.translatedText = result
                        self.isTranslating = false
                    }
                }
            } catch {
                if !Task.isCancelled {
                    DispatchQueue.main.async {
                        self.translatedText = "Error: \(error.localizedDescription)"
                        self.isTranslating = false
                    }
                }
            }
        }
    }
}
