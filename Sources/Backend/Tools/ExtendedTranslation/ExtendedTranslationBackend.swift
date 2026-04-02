import Foundation
import AVFoundation
import Speech

class ExtendedTranslationBackend: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    @Published var inputText = ""
    @Published var translatedText = ""
    @Published var sourceLanguage = "en-US"
    @Published var targetLanguage = "es-ES"
    @Published var isListening = false
    @Published var isProcessing = false

    let speechSynthesizer = AVSpeechSynthesizer()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    override init() {
        super.init()
        setupRecognizer()
    }

    private func setupRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: sourceLanguage))
        speechRecognizer?.delegate = self
    }

    func translate() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isProcessing = true

        // Simulating translation with a rule-based prefix for functional feedback
        // In a real production app, this would call a translation API
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.translatedText = "[Translated to \(self.targetLanguage)]: " + text
            self.isProcessing = false
        }
    }

    func startSpeechToText() {
        if isListening {
            stopSpeechToText()
            return
        }

        isListening = true
        // Functional simulation of voice recognition for demonstration
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if self.isListening {
                self.inputText = "This is a recorded message for translation."
                self.isListening = false
                self.translate()
            }
        }
    }

    func stopSpeechToText() {
        isListening = false
    }

    func playSpeech() {
        let utterance = AVSpeechUtterance(string: translatedText)
        utterance.voice = AVSpeechSynthesisVoice(language: targetLanguage)
        speechSynthesizer.speak(utterance)
    }

    func updateSourceLanguage(_ code: String) {
        sourceLanguage = code
        setupRecognizer()
    }
}
