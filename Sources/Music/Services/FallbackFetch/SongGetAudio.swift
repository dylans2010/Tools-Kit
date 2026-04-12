import Foundation

class SongGetAudio {
    /// Calls the Zyla YouTube-to-Audio API to get an MP3 download URL for the given YouTube URL.
    /// - Parameters:
    ///   - youtubeURL: The full YouTube video URL (e.g. `https://www.youtube.com/watch?v=...`).
    ///   - zylaAPIKey: The Zyla Labs API key for the YouTube-to-Audio API (381).
    func getAudioLink(youtubeURL: String, zylaAPIKey: String) async throws -> URL? {
        guard var components = URLComponents(string: "https://zylalabs.com/api/381/youtube+to+audio+api/351/get+audio") else { return nil }
        components.queryItems = [URLQueryItem(name: "link", value: youtubeURL)]

        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = YouTubeAPIKey.headers(apiKey: zylaAPIKey)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse {
            print("Zyla audio API status: \(http.statusCode)")
            if let raw = String(data: data, encoding: .utf8) {
                print("Zyla audio API response: \(raw.prefix(500))")
            }
        }

        let audioResponse = try JSONDecoder().decode(AudioResponse.self, from: data)

        // Accept the link when present, regardless of status field value
        if let link = audioResponse.link, !link.isEmpty, let audioURL = URL(string: link) {
            return audioURL
        }

        // Surface a meaningful error message if available
        let reason = audioResponse.msg ?? audioResponse.error ?? "No audio link returned"
        throw SongGetAudioError.noLink(reason)
    }
}

enum SongGetAudioError: LocalizedError {
    case noLink(String)

    var errorDescription: String? {
        switch self {
        case .noLink(let reason): return "Audio extraction failed: \(reason)"
        }
    }
}

struct AudioResponse: Decodable {
    let link: String?
    let status: String?
    let msg: String?
    let error: String?
}
