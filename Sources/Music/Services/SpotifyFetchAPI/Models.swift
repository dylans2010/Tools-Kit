import Foundation

enum MatchSourceType: String, Codable {
    case local
    case external
    case none
}

enum MatchStatus: String, Codable {
    case queued
    case searching
    case matched
    case failed
    case downloaded
}

enum MatchReason: String, Codable {
    case exact
    case fuzzy
    case fallback
    case none
}

struct SpotifyTrack: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let artist: String
    let album: String?
    let duration: Double?
    let artworkURL: String?
}

struct MatchedTrack: Identifiable, Codable, Equatable {
    var id: String { original.id }
    let original: SpotifyTrack
    var matchedTitle: String?
    var matchedArtist: String?
    var sourceType: MatchSourceType
    var sourceURL: String?
    var confidence: Double
    var reason: MatchReason
    var status: MatchStatus
    var localFileURL: URL?

    var displayStatus: String {
        switch status {
        case .queued: return "Queued"
        case .searching: return "Matching..."
        case .matched: return "Matched"
        case .failed: return "Not Found"
        case .downloaded: return "Downloaded"
        }
    }
}
