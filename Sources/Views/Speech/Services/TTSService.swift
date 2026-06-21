import Foundation
import AVFoundation

protocol TTSServiceProtocol {
    func speak(text: String) async throws
    func stop()
}

class AppleTTSService: NSObject, TTSServiceProtocol, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    var voiceID: String?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(text: String) async throws {
        let utterance = AVSpeechUtterance(string: text)
        if let voiceID = voiceID {
            utterance.voice = AVSpeechSynthesisVoice(identifier: voiceID)
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate

        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

class ElevenLabsTTSService: TTSServiceProtocol {
    private var audioPlayer: AVAudioPlayer?
    var voiceID: String?

    func speak(text: String) async throws {
        let data = try await ElevenLabsService.shared.generateSpeech(text: text, voiceID: voiceID ?? "21m00Tcm4TlvDq8ikWAM")
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer?.play()

        // Wait for playback to finish
        while audioPlayer?.isPlaying == true {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    func stop() {
        audioPlayer?.stop()
    }
}

class TTSService: ObservableObject {
    static let shared = TTSService()

    @Published var provider: TTSProvider = .apple {
        didSet {
            UserDefaults.standard.set(provider.rawValue, forKey: "selected_tts_provider")
            updateCurrentService()
        }
    }

    @Published var selectedAppleVoiceID: String? {
        didSet {
            UserDefaults.standard.set(selectedAppleVoiceID, forKey: "selected_apple_voice_id")
            if let appleService = currentService as? AppleTTSService {
                appleService.voiceID = selectedAppleVoiceID
            }
        }
    }

    @Published var selectedElevenLabsVoiceID: String? {
        didSet {
            UserDefaults.standard.set(selectedElevenLabsVoiceID, forKey: "selected_eleven_labs_voice_id")
            if let elevenService = currentService as? ElevenLabsTTSService {
                elevenService.voiceID = selectedElevenLabsVoiceID
            }
        }
    }

    private var currentService: TTSServiceProtocol

    private init() {
        let savedProvider = UserDefaults.standard.string(forKey: "selected_tts_provider") ?? TTSProvider.apple.rawValue
        let provider = TTSProvider(rawValue: savedProvider) ?? .apple
        self.provider = provider

        self.selectedAppleVoiceID = UserDefaults.standard.string(forKey: "selected_apple_voice_id")
        self.selectedElevenLabsVoiceID = UserDefaults.standard.string(forKey: "selected_eleven_labs_voice_id")

        if provider == .elevenLabs {
            let service = ElevenLabsTTSService()
            service.voiceID = selectedElevenLabsVoiceID
            self.currentService = service
        } else {
            let service = AppleTTSService()
            service.voiceID = selectedAppleVoiceID
            self.currentService = service
        }
    }

    private func updateCurrentService() {
        if provider == .elevenLabs {
            let service = ElevenLabsTTSService()
            service.voiceID = selectedElevenLabsVoiceID
            self.currentService = service
        } else {
            let service = AppleTTSService()
            service.voiceID = selectedAppleVoiceID
            self.currentService = service
        }
    }

    func speak(text: String) async throws {
        try await currentService.speak(text: text)
    }

    func stop() {
        currentService.stop()
    }
}
