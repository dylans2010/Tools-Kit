import Foundation
import UIKit

/// Handles Spotify URL parsing and safe deep-link playback.
/// Does NOT attempt audio extraction – playback is delegated to the Spotify app.
final class SpotifyLinkService: ObservableObject {

    enum SpotifyItemType {
        case track, playlist, album, artist
    }

    struct SpotifyItem {
        let type: SpotifyItemType
        let id: String
        let displayTitle: String

        var deepLink: URL? {
            switch type {
            case .track:    return URL(string: "spotify://track/\(id)")
            case .playlist: return URL(string: "spotify://playlist/\(id)")
            case .album:    return URL(string: "spotify://album/\(id)")
            case .artist:   return URL(string: "spotify://artist/\(id)")
            }
        }

        var webURL: URL? {
            switch type {
            case .track:    return URL(string: "https://open.spotify.com/track/\(id)")
            case .playlist: return URL(string: "https://open.spotify.com/playlist/\(id)")
            case .album:    return URL(string: "https://open.spotify.com/album/\(id)")
            case .artist:   return URL(string: "https://open.spotify.com/artist/\(id)")
            }
        }
    }

    @Published var currentItem: SpotifyItem?
    @Published var errorMessage: String?

    // MARK: - Parse

    /// Parses a Spotify URL (open.spotify.com or spotify://) and returns a SpotifyItem.
    func parse(urlString: String) -> SpotifyItem? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else {
            errorMessage = "Invalid URL."
            return nil
        }

        // Handles both https://open.spotify.com/track/ID and spotify://track/ID
        let pathComponents: [String]
        if url.scheme == "spotify" {
            pathComponents = url.host.map { [$0] + (url.pathComponents.filter { $0 != "/" }) } ?? []
        } else if url.host?.contains("spotify.com") == true {
            pathComponents = url.pathComponents.filter { $0 != "/" }
        } else {
            errorMessage = "Not a Spotify URL."
            return nil
        }

        guard pathComponents.count >= 2 else {
            errorMessage = "Could not parse Spotify link."
            return nil
        }

        let typeStr = pathComponents[0]
        let itemID  = pathComponents[1]

        let type: SpotifyItemType
        switch typeStr {
        case "track":    type = .track
        case "playlist": type = .playlist
        case "album":    type = .album
        case "artist":   type = .artist
        default:
            errorMessage = "Unsupported Spotify item type: \(typeStr)."
            return nil
        }

        let title: String
        switch type {
        case .track:    title = "Spotify Track"
        case .playlist: title = "Spotify Playlist"
        case .album:    title = "Spotify Album"
        case .artist:   title = "Spotify Artist"
        }

        errorMessage = nil
        let item = SpotifyItem(type: type, id: itemID, displayTitle: title)
        currentItem = item
        return item
    }

    // MARK: - Open in Spotify

    func openInSpotify(_ item: SpotifyItem) {
        if let deepLink = item.deepLink,
           UIApplication.shared.canOpenURL(deepLink) {
            UIApplication.shared.open(deepLink)
        } else if let web = item.webURL {
            UIApplication.shared.open(web)
        }
    }

    var isSpotifyInstalled: Bool {
        guard let url = URL(string: "spotify://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}
