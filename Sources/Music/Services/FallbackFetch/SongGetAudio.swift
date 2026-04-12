import Foundation

class SongGetAudio {
    func getAudioLink(youtubeURL: String, apiKey: String) async throws -> URL? {
        let urlString = "https://zylalabs.com/api/381/youtube+to+audio+api/351/get+audio?link=\(youtubeURL)"
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = YouTubeAPIKey.headers(apiKey: apiKey)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(AudioResponse.self, from: data)

        if response.status == "ok", let link = response.link {
            return URL(string: link)
        }

        return nil
    }
}

struct AudioResponse: Decodable {
    let link: String?
    let status: String?
    let msg: String?
}
