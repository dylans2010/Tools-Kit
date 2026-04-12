import Foundation

struct YouTubeAPIKey {
    static func headers(apiKey: String) -> [String: String] {
        return [
            "Authorization": "Bearer \(apiKey)",
            "Accept": "application/json"
        ]
    }
}
