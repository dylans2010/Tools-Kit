import Foundation

struct YouTubeAPIKey: Sendable {
    static func headers(apiKey: String) -> [String: String] {
        return [
            "Authorization": "Bearer \(apiKey)",
            "Accept": "application/json"
        ]
    }
}
