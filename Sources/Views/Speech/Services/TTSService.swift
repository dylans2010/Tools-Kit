import Foundation
import AVFoundation

protocol TTSServiceProtocol {
    func speak(text: String) async throws
    func stop()
    
    // Customization support
    var pace: Float { get set }
    var expressiveness: Float { get set }
}

class AppleTTSService: NSObject, TTSServiceProtocol, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    var voiceID: String?
    
    // Pace maps to rate (0.0 to 1.0, default 0.5)
    var pace: Float = AVSpeechUtteranceDefaultSpeechRate
    
    // Expressiveness maps to pitchMultiplier (0.5 to 2.0, default 1.0)
    var expressiveness: Float = 1.0

    private var continuation: CheckedContinuation<Void, Error>?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(text: String) async throws {
        stop()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.continuation = continuation

            let utterance = AVSpeechUtterance(string: text)
            if let voiceID = voiceID {
                utterance.voice = AVSpeechSynthesisVoice(identifier: voiceID)
            } else {
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            }
            utterance.rate = pace
            utterance.pitchMultiplier = expressiveness

            synthesizer.speak(utterance)

            // Safety check: if it's not speaking after a small delay, resume to avoid hang
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                if !self.synthesizer.isSpeaking && self.continuation != nil {
                    self.continuation?.resume(returning: ())
                    self.continuation = nil
                }
            }
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        continuation?.resume(returning: ())
        continuation = nil
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        continuation?.resume(returning: ())
        continuation = nil
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        continuation?.resume(returning: ())
        continuation = nil
    }
}

class ElevenLabsTTSService: NSObject, TTSServiceProtocol, AVAudioPlayerDelegate {
    private var audioPlayer: AVAudioPlayer?
    var voiceID: String?
    
    // Pace is not directly mapped well in standard ElevenLabs API without SSML, 
    // but we can adjust stability as expressiveness and similarity as pace, 
    // or keep them as stability/similarity. Let's map pace -> similarity, expressiveness -> stability (inverted).
    var pace: Float = 0.5 // similarityBoost
    var expressiveness: Float = 0.5 // stability

    private var continuation: CheckedContinuation<Void, Error>?

    func speak(text: String) async throws {
        stop()

        let data = try await ElevenLabsService.shared.generateSpeech(
            text: text,
            voiceID: voiceID ?? "21m00Tcm4TlvDq8ikWAM",
            stability: expressiveness,
            similarityBoost: pace
        )

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.continuation = continuation
            do {
                let player = try AVAudioPlayer(data: data)
                audioPlayer = player
                player.delegate = self
                if !player.play() {
                    continuation.resume(returning: ())
                    self.continuation = nil
                }
            } catch {
                continuation.resume(throwing: error)
                self.continuation = nil
            }
        }
    }

    func stop() {
        audioPlayer?.stop()
        continuation?.resume(returning: ())
        continuation = nil
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        continuation?.resume(returning: ())
        continuation = nil
    }
}

class TTSService: ObservableObject {
    static let shared = TTSService()

    @Published var provider: TTSProvider = .apple {
        didSet {
            SDKLogStore.shared.log("TTS Provider changed to \(provider.rawValue)", source: "TTSService", level: .info)
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

    @Published var useSystemFallback: Bool {
        didSet {
            UserDefaults.standard.set(useSystemFallback, forKey: "use_system_tts_fallback")
        }
    }
    
    @Published var pace: Float {
        didSet {
            let clamped = min(max(pace, 0.0), 1.0)
            if pace != clamped { pace = clamped }
            UserDefaults.standard.set(pace, forKey: "selected_voice_pace")
            currentService.pace = pace
        }
    }
    
    @Published var expressiveness: Float {
        didSet {
            let clamped = min(max(expressiveness, 0.0), 1.0)
            if expressiveness != clamped { expressiveness = clamped }
            UserDefaults.standard.set(expressiveness, forKey: "selected_voice_expressiveness")
            currentService.expressiveness = expressiveness
        }
    }

    private var currentService: TTSServiceProtocol

    private init() {
        let savedProvider = UserDefaults.standard.string(forKey: "selected_tts_provider") ?? TTSProvider.apple.rawValue
        let provider = TTSProvider(rawValue: savedProvider) ?? .apple
        self.provider = provider

        let appleVoice = UserDefaults.standard.string(forKey: "selected_apple_voice_id")
        self.selectedAppleVoiceID = appleVoice
        
        let elevenLabsVoice = UserDefaults.standard.string(forKey: "selected_eleven_labs_voice_id")
        self.selectedElevenLabsVoiceID = elevenLabsVoice
        
        let savedPace = UserDefaults.standard.object(forKey: "selected_voice_pace") as? Float ?? AVSpeechUtteranceDefaultSpeechRate
        self.pace = savedPace
        
        let savedExpressiveness = UserDefaults.standard.object(forKey: "selected_voice_expressiveness") as? Float ?? 1.0
        self.expressiveness = savedExpressiveness

        self.useSystemFallback = UserDefaults.standard.bool(forKey: "use_system_tts_fallback")

        if provider == .elevenLabs {
            let service = ElevenLabsTTSService()
            service.voiceID = elevenLabsVoice
            service.pace = savedPace
            service.expressiveness = savedExpressiveness
            self.currentService = service
        } else {
            let service = AppleTTSService()
            service.voiceID = appleVoice
            service.pace = savedPace
            service.expressiveness = savedExpressiveness
            self.currentService = service
        }
    }

    private func updateCurrentService() {
        if provider == .elevenLabs {
            let service = ElevenLabsTTSService()
            service.voiceID = selectedElevenLabsVoiceID
            service.pace = pace
            service.expressiveness = expressiveness
            self.currentService = service
        } else {
            let service = AppleTTSService()
            service.voiceID = selectedAppleVoiceID
            service.pace = pace
            service.expressiveness = expressiveness
            self.currentService = service
        }
    }

    func speak(text: String) async throws {
        do {
            try await currentService.speak(text: text)
        } catch {
            if provider == .elevenLabs && useSystemFallback {
                SDKLogStore.shared.log("ElevenLabs failed, falling back to Apple TTS", source: "TTSService", level: .warning)
                let fallbackService = AppleTTSService()
                fallbackService.voiceID = selectedAppleVoiceID
                fallbackService.pace = pace
                fallbackService.expressiveness = expressiveness
                try await fallbackService.speak(text: text)
            } else {
                throw error
            }
        }
    }

    func speakWithProvider(text: String, provider: TTSProvider, voiceID: String?) async throws {
        let service: TTSServiceProtocol
        if provider == .elevenLabs {
            let elevenService = ElevenLabsTTSService()
            elevenService.voiceID = voiceID
            elevenService.pace = pace
            elevenService.expressiveness = expressiveness
            service = elevenService
        } else {
            let appleService = AppleTTSService()
            appleService.voiceID = voiceID
            appleService.pace = pace
            appleService.expressiveness = expressiveness
            service = appleService
        }

        do {
            try await service.speak(text: text)
        } catch {
            if provider == .elevenLabs && useSystemFallback {
                SDKLogStore.shared.log("ElevenLabs failed, falling back to Apple TTS", source: "TTSService", level: .warning)
                let fallbackService = AppleTTSService()
                fallbackService.voiceID = selectedAppleVoiceID
                fallbackService.pace = pace
                fallbackService.expressiveness = expressiveness
                try await fallbackService.speak(text: text)
            } else {
                throw error
            }
        }
    }

    func stop() {
        currentService.stop()
    }
}
