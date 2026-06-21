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
        utterance.rate = pace
        utterance.pitchMultiplier = expressiveness

        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

class ElevenLabsTTSService: TTSServiceProtocol {
    private var audioPlayer: AVAudioPlayer?
    var voiceID: String?
    
    // Pace is not directly mapped well in standard ElevenLabs API without SSML, 
    // but we can adjust stability as expressiveness and similarity as pace, 
    // or keep them as stability/similarity. Let's map pace -> similarity, expressiveness -> stability (inverted).
    var pace: Float = 0.5 // similarityBoost
    var expressiveness: Float = 0.5 // stability

    func speak(text: String) async throws {
        let data = try await ElevenLabsService.shared.generateSpeech(
            text: text,
            voiceID: voiceID ?? "21m00Tcm4TlvDq8ikWAM",
            stability: expressiveness,
            similarityBoost: pace
        )
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
    
    @Published var pace: Float {
        didSet {
            UserDefaults.standard.set(pace, forKey: "selected_voice_pace")
            currentService.pace = pace
        }
    }
    
    @Published var expressiveness: Float {
        didSet {
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
        try await currentService.speak(text: text)
    }

    func stop() {
        currentService.stop()
    }
}
