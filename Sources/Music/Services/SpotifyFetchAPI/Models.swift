import Foundation

enum MatchSourceType: String, Codable {
    case local
    case external
    case none
}

enum MatchStatus: String, Codable {
    case searching
    case matched
    case failed
}

struct SpotifyTrack: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let artist: String
    let duration: Double?
}

struct MatchedTrack: Identifiable, Codable, Equatable {
    var id: String { original.id }
    let original: SpotifyTrack
    var matchedTitle: String?
    var matchedArtist: String?
    var sourceType: MatchSourceType
    var sourceURL: String?
    var confidence: Double
    var status: MatchStatus
}
