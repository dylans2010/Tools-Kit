import Foundation

class SongGetAudio {
    private let maxAttempts = 5
    private let pollDelayNanoseconds: UInt64 = 2_000_000_000

    /// Calls the Zyla YouTube-to-Audio API to get an MP3 download URL for the given YouTube URL.
    /// - Parameters:
    ///   - youtubeURL: The full YouTube video URL (e.g. `https://www.youtube.com/watch?v=...`).
    ///   - zylaAPIKey: The Zyla Labs API key for the YouTube-to-Audio API (381).
    func getAudioLink(youtubeURL: String, zylaAPIKey: String) async throws -> URL {
        print("[FallbackFetch][Zyla] Requesting audio link for \(youtubeURL)")
        var lastResponse: AudioResponse?

        for attempt in 1...maxAttempts {
            do {
                let response = try await performRequest(
                    youtubeURL: youtubeURL,
                    zylaAPIKey: zylaAPIKey,
                    attempt: attempt
                )
                lastResponse = response

                if let link = response.link, !link.isEmpty, let audioURL = URL(string: link) {
                    print("[FallbackFetch][Zyla] Link ready on attempt \(attempt)")
                    return audioURL
                }

                let statusText = response.status ?? "pending"
                print("[FallbackFetch][Zyla] Attempt \(attempt) status=\(statusText); retrying...")
            } catch {
                if attempt == maxAttempts {
                    throw error
                }
                print("[FallbackFetch][Zyla] Attempt \(attempt) failed: \(error.localizedDescription). Retrying...")
            }

            if attempt < maxAttempts {
                try await Task.sleep(nanoseconds: pollDelayNanoseconds)
            }
        }

        let reason = lastResponse?.msg ?? lastResponse?.error ?? "No audio link returned after polling"
        throw SongGetAudioError.noLink(reason)
    }

    private func performRequest(youtubeURL: String, zylaAPIKey: String, attempt: Int) async throws -> AudioResponse {
        guard let url = URL(string: "https://zylalabs.com/api/381/youtube+to+audio+api/351/get+audio") else {
            throw SongGetAudioError.invalidURL("Failed to build Zyla API URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        YouTubeAPIKey.headers(apiKey: zylaAPIKey).forEach {
            request.setValue($0.value, forHTTPHeaderField: $0.key)
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: ["link": youtubeURL])

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse {
            print("[FallbackFetch][Zyla] Attempt \(attempt) status: \(http.statusCode)")
        }

        if let raw = String(data: data, encoding: .utf8) {
            print("[FallbackFetch][Zyla] Attempt \(attempt) response: \(raw.prefix(500))")
        }

        return try JSONDecoder().decode(AudioResponse.self, from: data)
    }
}

enum SongGetAudioError: LocalizedError, Sendable {
    case invalidURL(String)
    case noLink(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let reason): return "Audio extraction failed: \(reason)"
        case .noLink(let reason): return "Audio extraction failed: \(reason)"
        }
    }
}

struct AudioResponse: Decodable, Sendable {
    let link: String?
    let status: String?
    let msg: String?
    let error: String?
}
