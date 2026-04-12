import Foundation

struct TrackMatchingService {
    func match(track: SpotifyTrack, localSongs: [Song]) -> MatchedTrack {
        let normalizedTitle = normalize(track.title)
        let normalizedArtist = normalize(track.artist)

        var bestSong: Song?
        var bestScore: Double = 0

        for song in localSongs {
            let titleScore = similarity(normalizedTitle, normalize(song.title))
            let artistScore = similarity(normalizedArtist, normalize(song.artist))
            let score = (titleScore * 0.7) + (artistScore * 0.3)

            if score > bestScore {
                bestScore = score
                bestSong = song
            }
        }

        if let bestSong, bestScore >= 0.72 {
            return MatchedTrack(
                original: track,
                matchedTitle: bestSong.title,
                matchedArtist: bestSong.artist,
                sourceType: .local,
                sourceURL: bestSong.fileURL.absoluteString,
                confidence: bestScore,
                status: .matched
            )
        }

        let searchURL = youtubeSearchIntentURL(title: track.title, artist: track.artist)
        return MatchedTrack(
            original: track,
            matchedTitle: nil,
            matchedArtist: nil,
            sourceType: .external,
            sourceURL: searchURL?.absoluteString,
            confidence: 0,
            status: .failed
        )
    }

    func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined(separator: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func similarity(_ lhs: String, _ rhs: String) -> Double {
        guard !lhs.isEmpty, !rhs.isEmpty else { return 0 }
        if lhs == rhs { return 1.0 }
        if lhs.contains(rhs) || rhs.contains(lhs) { return 0.9 }

        let lhsTokens = Set(lhs.split(separator: " ").map(String.init))
        let rhsTokens = Set(rhs.split(separator: " ").map(String.init))

        let intersection = lhsTokens.intersection(rhsTokens).count
        let union = lhsTokens.union(rhsTokens).count
        guard union > 0 else { return 0 }
        return Double(intersection) / Double(union)
    }

    private func youtubeSearchIntentURL(title: String, artist: String) -> URL? {
        let query = "\(title) \(artist)"
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://www.youtube.com/results?search_query=\(encoded)")
    }
}
