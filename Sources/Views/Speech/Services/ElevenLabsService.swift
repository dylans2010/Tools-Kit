import Foundation

enum ElevenLabsError: Error {
    case missingAPIKey
    case invalidURL
    case networkError(String)
    case invalidResponse
    case decodingError
}

class ElevenLabsService {
    static let shared = ElevenLabsService()
    private let baseURL = "https://api.elevenlabs.io/v1"

    private init() {}

    func generateSpeech(text: String, voiceID: String = "21m00Tcm4TlvDq8ikWAM", stability: Float = 0.5, similarityBoost: Float = 0.5) async throws -> Data {
        // Enforce strict clamping 0.0 - 1.0 to prevent 422 errors
        let clampedStability = min(max(stability, 0.0), 1.0)
        let clampedSimilarity = min(max(similarityBoost, 0.0), 1.0)

        guard let apiKey = SpeechKeychainManager.shared.getKey() else {
            throw ElevenLabsError.missingAPIKey
        }

        let urlString = "\(baseURL)/text-to-speech/\(voiceID)"
        guard let url = URL(string: urlString) else {
            throw ElevenLabsError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")

        let body: [String: Any] = [
            "text": text,
            "model_id": "eleven_flash_v2_5",
            "voice_settings": [
                "stability": clampedStability,
                "similarity_boost": clampedSimilarity
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let payloadString = String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "No payload"
        SDKLogStore.shared.log("ElevenLabs TTS Request: \(text.prefix(50))... | Payload: \(payloadString)", source: "ElevenLabsService", level: .info)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            SDKLogStore.shared.log("ElevenLabs TTS: Invalid Response", source: "ElevenLabsService", level: .error)
            throw ElevenLabsError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            SDKLogStore.shared.log("ElevenLabs TTS Error: \(errorMsg)", source: "ElevenLabsService", level: .error, errorCode: httpResponse.statusCode)
            throw ElevenLabsError.networkError("Status: \(httpResponse.statusCode), \(errorMsg)")
        }

        SDKLogStore.shared.log("ElevenLabs TTS Success (200 OK)", source: "ElevenLabsService", level: .info)
        return data
    }

    func getVoices() async throws -> [ElevenLabsVoice] {
        guard let apiKey = SpeechKeychainManager.shared.getKey() else {
            throw ElevenLabsError.missingAPIKey
        }

        guard let url = URL(string: "\(baseURL)/voices") else {
            throw ElevenLabsError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ElevenLabsError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(ElevenLabsVoicesResponse.self, from: data)
        return decoded.voices
    }
}

struct ElevenLabsVoicesResponse: Codable {
    let voices: [ElevenLabsVoice]
}

struct ElevenLabsVoice: Codable, Identifiable {
    let voice_id: String
    let name: String
    let category: String?

    var id: String { voice_id }
}
