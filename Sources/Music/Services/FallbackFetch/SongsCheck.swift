import Foundation

struct YouTubeSearchResult: Decodable {
    let id: String
    let title: String
}

class SongsCheck {
    func search(query: String, apiKey: String) async -> [YouTubeSearchResult] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://zylalabs.com/api/2490/youtube+keyword+research+api/2384/get+results+by+keyword?keyword=\(encodedQuery)"

        guard let url = URL(string: urlString) else { return [] }

        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = YouTubeAPIKey.headers(apiKey: apiKey)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
            return response.videos.map { YouTubeSearchResult(id: $0.id, title: $0.title ?? "Unknown") }
        } catch {
            print("Search error: \(error)")
            return []
        }
    }
}

struct YouTubeSearchResponse: Decodable {
    let videos: [YouTubeVideo]

    struct YouTubeVideo: Decodable {
        let id: String
        let title: String?
    }
}
