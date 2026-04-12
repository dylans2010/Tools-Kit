import Foundation

struct YouTubeSearchResult {
    let id: String
    let title: String
}

class SongsCheck {
    /// Searches YouTube Data API v3 for videos matching the given query.
    /// - Parameters:
    ///   - query: The search query (song name + artist).
    ///   - youtubeAPIKey: A Google Cloud YouTube Data API v3 key.
    func search(query: String, youtubeAPIKey: String) async -> [YouTubeSearchResult] {
        guard var components = URLComponents(string: "https://www.googleapis.com/youtube/v3/search") else { return [] }
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "maxResults", value: "10"),
            URLQueryItem(name: "key", value: youtubeAPIKey)
        ]

        guard let url = components.url else { return [] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
            return response.items.map { item in
                YouTubeSearchResult(id: item.id.videoId, title: item.snippet.title)
            }
        } catch {
            print("YouTube search error: \(error)")
            return []
        }
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
        let videoId: String
    }

    struct Snippet: Decodable {
        let title: String
    }
}
