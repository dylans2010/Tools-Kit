import Foundation

enum TTSProvider: String, CaseIterable, Identifiable, Codable {
    case apple = "Apple"
    case elevenLabs = "ElevenLabs"

    var id: String { self.rawValue }

    var icon: String {
        switch self {
        case .apple: return "applelogo"
        case .elevenLabs: return "waveform"
        }
    }
}

struct SpeechMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: SpeechRole
    let content: String
    let timestamp: Date
    let audioURL: URL?

    init(id: UUID = UUID(), role: SpeechRole, content: String, timestamp: Date = Date(), audioURL: URL? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.audioURL = audioURL
    }
}

enum SpeechRole: String, Codable {
    case user
    case assistant
    case system
}

enum SpeechSessionMode {
    case voice
    case text
    case vision
}

enum VisionProvider: String, CaseIterable, Identifiable, Codable {
    case openai = "OpenAI"
    case gemini = "Google Gemini"

    var id: String { self.rawValue }
}

/// Represents the current state of the voice interface
enum SpeechState: Equatable {
    case idle
    case listening
    case processing
    case speaking
    case error(String)

    var statusText: String {
        switch self {
        case .idle: return "Tap to Speak"
        case .listening: return "Listening..."
        case .processing: return "Thinking..."
        case .speaking: return "Speaking..."
        case .error(let msg): return msg
        }
    }

    var isActive: Bool {
        switch self {
        case .idle, .error: return false
        default: return true
        }
    }
}

/// Structured error type for the speech system
enum SpeechError: LocalizedError {
    case missingAIProvider
    case missingAPIKey(String)
    case aiServiceError(String)
    case ttsError(String)
    case visionError(String)
    case speechRecognitionError(String)
    case cameraError(String)

    var errorDescription: String? {
        switch self {
        case .missingAIProvider:
            return "No AI provider configured. Please set up an AI provider in Settings."
        case .missingAPIKey(let service):
            return "Missing API key for \(service). Please add it in Speech Settings."
        case .aiServiceError(let detail):
            return "AI error: \(detail)"
        case .ttsError(let detail):
            return "Speech error: \(detail)"
        case .visionError(let detail):
            return "Vision error: \(detail)"
        case .speechRecognitionError(let detail):
            return "Recognition error: \(detail)"
        case .cameraError(let detail):
            return "Camera error: \(detail)"
        }
    }

    /// Short spoken version of the error for voice mode
    var spokenMessage: String {
        switch self {
        case .missingAIProvider:
            return "No AI provider is configured. Please check your settings."
        case .missingAPIKey(let service):
            return "Missing API key for \(service). Please check your settings."
        case .aiServiceError:
            return "I encountered an error processing your request. Please try again."
        case .ttsError:
            return "I had trouble speaking. Please try again."
        case .visionError:
            return "I couldn't analyze what I'm seeing. Please try again."
        case .speechRecognitionError:
            return "I didn't catch that. Please try again."
        case .cameraError:
            return "Camera is not available."
        }
    }
}
