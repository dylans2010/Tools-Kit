import Foundation

struct YouTubeSearchResult {
    let id: String
    let title: String

    var url: String { "https://www.youtube.com/watch?v=\(id)" }
}

enum SongsCheckError: LocalizedError {
    case invalidRequest(String)

    var errorDescription: String? {
        switch self {
        case .invalidRequest(let message): return message
        }
    }
}

class SongsCheck {
    /// Searches YouTube Data API v3 for videos matching the given query.
    /// - Parameters:
    ///   - query: The search query (song name + artist).
    ///   - youtubeAPIKey: A Google Cloud YouTube Data API v3 key.
    func search(query: String, youtubeAPIKey: String) async throws -> [YouTubeSearchResult] {
        guard var components = URLComponents(string: "https://www.googleapis.com/youtube/v3/search") else {
            throw SongsCheckError.invalidRequest("Failed to build YouTube search URL")
        }
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "maxResults", value: "10"),
            URLQueryItem(name: "key", value: youtubeAPIKey)
        ]

        guard let url = components.url else {
            throw SongsCheckError.invalidRequest("Failed to create YouTube search request URL")
        }

        print("[FallbackFetch][YouTube] Searching for \"\(query)\"")
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse {
            print("[FallbackFetch][YouTube] Status: \(http.statusCode)")
        }

        let decoded = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
        let results = decoded.items.compactMap { item -> YouTubeSearchResult? in
            guard let videoId = item.id.videoId?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !videoId.isEmpty else { return nil }
            return YouTubeSearchResult(id: videoId, title: item.snippet.title)
        }

        print("[FallbackFetch][YouTube] Found \(results.count) candidates")
        return results
    }
}

// MARK: - YouTube Data API v3 response models

private struct YouTubeSearchResponse: Decodable {
    let items: [Item]

    struct Item: Decodable {
        let id: VideoID
        let snippet: Snippet
    }

    struct VideoID: Decodable {
        let videoId: String?
    }

    struct Snippet: Decodable {
        let title: String
    }
}
