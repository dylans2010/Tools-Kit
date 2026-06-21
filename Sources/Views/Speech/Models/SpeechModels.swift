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
}
