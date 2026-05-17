import Foundation

actor TrackMatchingService {
    private var matchCache: [String: MatchedTrack] = [:]
    private let cacheURL: URL

    init() {
        let musicDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Music", isDirectory: true)
        self.cacheURL = musicDirectory.appendingPathComponent("match-cache.json")
        // Load cache in a separate task or just synchronously since we are in init (but it's an actor)
        // For actors, sync init is fine, but we need to be careful with state.
        if let data = try? Data(contentsOf: cacheURL),
           let decoded = try? JSONDecoder().decode([String: MatchedTrack].self, from: data) {
            self.matchCache = decoded
        }
    }

    func match(track: SpotifyTrack, localSongs: [Song]) async -> MatchedTrack {
        let cacheKey = "\(track.id)"
        if let cached = matchCache[cacheKey] {
            // Verify local file still exists
            if cached.sourceType == .local, let urlString = cached.sourceURL, let url = URL(string: urlString),
               FileManager.default.fileExists(atPath: url.path) {
                return cached
            }
        }

        let normalizedTitle = normalize(track.title)
        let normalizedArtist = normalize(track.artist)

        // Pass 1: Exact Match
        if let exactMatch = findExactMatch(title: normalizedTitle, artist: normalizedArtist, localSongs: localSongs) {
            let result = MatchedTrack(
                original: track,
                matchedTitle: exactMatch.title,
                matchedArtist: exactMatch.artist,
                sourceType: .local,
                sourceURL: exactMatch.fileURL.absoluteString,
                confidence: 1.0,
                reason: .exact,
                status: .matched
            )
            updateCache(key: cacheKey, result: result)
            return result
        }

        // Pass 2: Fuzzy Match
        if let fuzzyMatch = findFuzzyMatch(title: normalizedTitle, artist: normalizedArtist, localSongs: localSongs) {
            let result = MatchedTrack(
                original: track,
                matchedTitle: fuzzyMatch.song.title,
                matchedArtist: fuzzyMatch.song.artist,
                sourceType: .local,
                sourceURL: fuzzyMatch.song.fileURL.absoluteString,
                confidence: fuzzyMatch.score,
                reason: .fuzzy,
                status: .matched
            )
            updateCache(key: cacheKey, result: result)
            return result
        }

        // Pass 3: Partial Match (Title only fallback)
        if let partialMatch = findPartialMatch(title: normalizedTitle, localSongs: localSongs) {
            let result = MatchedTrack(
                original: track,
                matchedTitle: partialMatch.song.title,
                matchedArtist: partialMatch.song.artist,
                sourceType: .local,
                sourceURL: partialMatch.song.fileURL.absoluteString,
                confidence: partialMatch.score,
                reason: .fallback,
                status: .matched
            )
            updateCache(key: cacheKey, result: result)
            return result
        }

        // No local match, provide external search URL
        let searchURL = youtubeSearchIntentURL(title: track.title, artist: track.artist)
        let result = MatchedTrack(
            original: track,
            matchedTitle: nil,
            matchedArtist: nil,
            sourceType: .external,
            sourceURL: searchURL?.absoluteString,
            confidence: 0,
            reason: .none,
            status: .failed
        )
        return result
    }

    private func findExactMatch(title: String, artist: String, localSongs: [Song]) -> Song? {
        localSongs.first { song in
            normalize(song.title) == title && normalize(song.artist) == artist
        }
    }

    private func findFuzzyMatch(title: String, artist: String, localSongs: [Song]) -> (song: Song, score: Double)? {
        var bestSong: Song?
        var bestScore: Double = 0

        for song in localSongs {
            let titleScore = levenshteinSimilarity(title, normalize(song.title))
            let artistScore = levenshteinSimilarity(artist, normalize(song.artist))
            let combinedScore = (titleScore * 0.7) + (artistScore * 0.3)

            if combinedScore > bestScore {
                bestScore = combinedScore
                bestSong = song
            }
        }

        if let bestSong, bestScore >= 0.75 {
            return (bestSong, bestScore)
        }
        return nil
    }

    private func findPartialMatch(title: String, localSongs: [Song]) -> (song: Song, score: Double)? {
        var bestSong: Song?
        var bestScore: Double = 0

        for song in localSongs {
            let songTitle = normalize(song.title)
            let score = levenshteinSimilarity(title, songTitle)

            if score > bestScore {
                bestScore = score
                bestSong = song
            }
        }

        if let bestSong, bestScore >= 0.85 {
            return (bestSong, bestScore * 0.8) // Penalize confidence for partial match
        }
        return nil
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

    private func levenshteinSimilarity(_ s1: String, _ s2: String) -> Double {
        let empty = [Int](repeating: 0, count: s2.count + 1)
        var last = [Int](0...s2.count)

        for (i, char1) in s1.enumerated() {
            var current = [i + 1] + empty.dropFirst()
            for (j, char2) in s2.enumerated() {
                current[j + 1] = char1 == char2 ? last[j] : min(last[j], last[j + 1], current[j]) + 1
            }
            last = current
        }

        let distance = Double(last.last ?? 0)
        let maxLength = Double(max(s1.count, s2.count))
        guard maxLength > 0 else { return 1.0 }
        return 1.0 - (distance / maxLength)
    }

    private func youtubeSearchIntentURL(title: String, artist: String) -> URL? {
        let query = "\(title) \(artist)"
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://www.youtube.com/results?search_query=\(encoded)")
    }

    // MARK: - Caching

    private func updateCache(key: String, result: MatchedTrack) {
        matchCache[key] = result
        saveCache()
    }

    private func saveCache() {
        guard let data = try? JSONEncoder().encode(matchCache) else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }
}
