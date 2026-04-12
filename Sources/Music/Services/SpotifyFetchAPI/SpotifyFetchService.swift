import Foundation

actor SpotifyFetchService {
    enum Error: LocalizedError {
        case invalidURL
        case invalidPlaylistURL
        case requestFailed
        case parseFailed

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL."
            case .invalidPlaylistURL:
                return "Could not extract a Spotify playlist ID from this URL."
            case .requestFailed:
                return "Could not load the Spotify playlist page."
            case .parseFailed:
                return "Could not parse playlist tracks from the page."
            }
        }
    }

    private struct CachedPlaylist: Codable {
        let playlistID: String
        let tracks: [SpotifyTrack]
        let savedAt: Date
    }

    private var cache: [String: CachedPlaylist] = [:]
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
        self.cache = loadCache()
    }

    func fetchPlaylistTracks(from playlistURLString: String) async throws -> [SpotifyTrack] {
        guard let playlistID = extractPlaylistID(from: playlistURLString) else {
            throw Error.invalidPlaylistURL
        }

        if let cached = cache[playlistID], !cached.tracks.isEmpty {
            return cached.tracks
        }

        guard let url = URL(string: "https://open.spotify.com/playlist/\(playlistID)") else {
            throw Error.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode,
              let html = String(data: data, encoding: .utf8) else {
            throw Error.requestFailed
        }

        let tracks = parseTracks(from: html, playlistID: playlistID)
        guard !tracks.isEmpty else {
            throw Error.parseFailed
        }

        cache[playlistID] = CachedPlaylist(playlistID: playlistID, tracks: tracks, savedAt: Date())
        saveCache(cache)
        return tracks
    }

    func parseManualTrackList(_ manualInput: String) -> [SpotifyTrack] {
        let lines = manualInput
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return lines.enumerated().map { index, line in
            let parts = line.components(separatedBy: " - ")
            let title = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? line
            let artist = parts.dropFirst().joined(separator: " - ").trimmingCharacters(in: .whitespacesAndNewlines)
            return SpotifyTrack(
                id: "manual-\(index)-\(UUID().uuidString)",
                title: title.isEmpty ? "Unknown Title" : title,
                artist: artist.isEmpty ? "Unknown Artist" : artist,
                duration: nil
            )
        }
    }

    func extractPlaylistID(from urlString: String) -> String? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else { return nil }

        if url.scheme == "spotify" {
            if url.host == "playlist" {
                return url.pathComponents.first(where: { $0 != "/" })
            }
            return nil
        }

        guard url.host?.contains("spotify.com") == true else { return nil }
        let components = url.pathComponents.filter { $0 != "/" }
        guard components.count >= 2, components[0] == "playlist" else { return nil }
        return components[1]
    }

    private func parseTracks(from html: String, playlistID: String) -> [SpotifyTrack] {
        var tracks: [SpotifyTrack] = []

        let candidates = jsonCandidates(from: html)
        for candidate in candidates {
            guard let data = candidate.data(using: .utf8) else { continue }
            if let jsonObject = try? JSONSerialization.jsonObject(with: data) {
                tracks.append(contentsOf: extractTracks(from: jsonObject, playlistID: playlistID))
            }
        }

        return deduplicatedTracks(tracks)
    }

    private func jsonCandidates(from html: String) -> [String] {
        var candidates: [String] = []

        let scriptPattern = #"<script[^>]*>(.*?)</script>"#
        let scriptRegex = try? NSRegularExpression(pattern: scriptPattern, options: [.dotMatchesLineSeparators, .caseInsensitive])
        let nsRange = NSRange(location: 0, length: html.utf16.count)

        scriptRegex?.enumerateMatches(in: html, options: [], range: nsRange) { match, _, _ in
            guard let match,
                  let range = Range(match.range(at: 1), in: html) else { return }
            let scriptContent = html[range].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !scriptContent.isEmpty else { return }

            if scriptContent.first == "{" || scriptContent.first == "[" {
                candidates.append(scriptContent)
            }

            if let assignmentJSON = extractAssignedJSONObject(from: scriptContent) {
                candidates.append(assignmentJSON)
            }
        }

        return candidates
    }

    private func extractAssignedJSONObject(from script: String) -> String? {
        guard let equalsIndex = script.firstIndex(of: "=") else { return nil }
        let rhs = script[script.index(after: equalsIndex)...]
        guard let openIndex = rhs.firstIndex(of: "{") else { return nil }

        var depth = 0
        var isInsideString = false
        var escaped = false
        var result = String()

        for char in rhs[openIndex...] {
            result.append(char)

            if escaped {
                escaped = false
                continue
            }

            if char == "\\" {
                escaped = true
                continue
            }

            if char == "\"" {
                isInsideString.toggle()
                continue
            }

            if isInsideString { continue }

            if char == "{" { depth += 1 }
            if char == "}" {
                depth -= 1
                if depth == 0 {
                    return result
                }
            }
        }

        return nil
    }

    private func extractTracks(from jsonObject: Any, playlistID: String) -> [SpotifyTrack] {
        var found: [SpotifyTrack] = []
        var index = 0

        func walk(_ value: Any) {
            if let dictionary = value as? [String: Any] {
                if let track = spotifyTrack(from: dictionary, playlistID: playlistID, index: index) {
                    found.append(track)
                    index += 1
                }
                for nested in dictionary.values {
                    walk(nested)
                }
            } else if let array = value as? [Any] {
                for nested in array {
                    walk(nested)
                }
            }
        }

        walk(jsonObject)
        return found
    }

    private func spotifyTrack(from dictionary: [String: Any], playlistID: String, index: Int) -> SpotifyTrack? {
        guard let title = dictionary["name"] as? String,
              !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        var artistNames: [String] = []

        if let artists = dictionary["artists"] as? [[String: Any]] {
            artistNames = artists.compactMap { $0["name"] as? String }
        } else if let byArtist = dictionary["byArtist"] as? [String: Any],
                  let artistName = byArtist["name"] as? String {
            artistNames = [artistName]
        } else if let artistString = dictionary["artist"] as? String {
            artistNames = [artistString]
        }

        let artist = artistNames.joined(separator: ", ").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !artist.isEmpty else { return nil }

        let durationMilliseconds = dictionary["duration_ms"] as? Double
            ?? (dictionary["duration_ms"] as? Int).map(Double.init)
            ?? (dictionary["duration"] as? Double)
            ?? (dictionary["duration"] as? Int).map(Double.init)

        let durationSeconds: Double?
        if let durationMilliseconds, durationMilliseconds > 1000 {
            durationSeconds = durationMilliseconds / 1000
        } else {
            durationSeconds = durationMilliseconds
        }

        let id = (dictionary["id"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedID = (id?.isEmpty == false ? id! : "\(playlistID)-\(index)")

        return SpotifyTrack(id: resolvedID, title: title, artist: artist, duration: durationSeconds)
    }

    private func deduplicatedTracks(_ tracks: [SpotifyTrack]) -> [SpotifyTrack] {
        var seen = Set<String>()
        var result: [SpotifyTrack] = []

        for track in tracks {
            let key = "\(track.title.lowercased())|\(track.artist.lowercased())"
            if seen.contains(key) { continue }
            seen.insert(key)
            result.append(track)
        }

        return result
    }

    private var cacheURL: URL {
        let musicDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Music", isDirectory: true)
        try? FileManager.default.createDirectory(at: musicDirectory, withIntermediateDirectories: true)
        return musicDirectory.appendingPathComponent("spotify-playlist-cache.json")
    }

    private func loadCache() -> [String: CachedPlaylist] {
        guard let data = try? Data(contentsOf: cacheURL),
              let decoded = try? JSONDecoder().decode([String: CachedPlaylist].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private func saveCache(_ value: [String: CachedPlaylist]) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }
}
