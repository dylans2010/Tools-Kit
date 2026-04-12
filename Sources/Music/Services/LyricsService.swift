import Foundation

final class LyricsService {

    // MARK: - LRCLIB

    private let baseURL = "https://lrclib.net/api"

    func fetchSyncedLyrics(for song: Song) async -> [LyricLine]? {
        var components = URLComponents(string: "\(baseURL)/get")
        var items: [URLQueryItem] = [
            URLQueryItem(name: "track_name", value: song.title),
            URLQueryItem(name: "artist_name", value: song.artist)
        ]
        if song.duration > 0 {
            items.append(URLQueryItem(name: "duration", value: String(Int(song.duration))))
        }
        components?.queryItems = items
        guard let url = components?.url else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            let decoded = try JSONDecoder().decode(LRCLIBResponse.self, from: data)
            guard let synced = decoded.syncedLyrics, !synced.isEmpty else { return nil }
            return parseLRC(synced)
        } catch {
            return nil
        }
    }

    // MARK: - LRC Parsing

    func parseLRC(_ lrc: String) -> [LyricLine] {
        var lines: [LyricLine] = []
        for raw in lrc.components(separatedBy: "\n") {
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("["),
                  let close = trimmed.firstIndex(of: "]") else { continue }

            let timeStr = String(trimmed[trimmed.index(after: trimmed.startIndex)..<close])
            let text = String(trimmed[trimmed.index(after: close)...]).trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty, let ts = parseTimestamp(timeStr) else { continue }
            lines.append(LyricLine(timestamp: ts, text: text))
        }
        return lines.sorted { $0.timestamp < $1.timestamp }
    }

    func exportLRC(_ lines: [LyricLine]) -> String {
        lines.map { line in
            let m = Int(line.timestamp) / 60
            let s = line.timestamp.truncatingRemainder(dividingBy: 60)
            return String(format: "[%02d:%05.2f] %@", m, s, line.text)
        }.joined(separator: "\n")
    }

    private func parseTimestamp(_ str: String) -> TimeInterval? {
        let parts = str.split(separator: ":").map(String.init)
        guard parts.count == 2,
              let minutes = Double(parts[0]),
              let seconds = Double(parts[1]) else { return nil }
        return minutes * 60 + seconds
    }

    // MARK: - Persistence

    private var lyricsDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Lyrics", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func save(_ lines: [LyricLine], for song: Song) {
        let url = lyricsDirectory.appendingPathComponent("\(song.id.uuidString).lrc")
        try? exportLRC(lines).write(to: url, atomically: true, encoding: .utf8)
    }

    func loadSaved(for song: Song) -> [LyricLine]? {
        let url = lyricsDirectory.appendingPathComponent("\(song.id.uuidString).lrc")
        guard let lrc = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let parsed = parseLRC(lrc)
        return parsed.isEmpty ? nil : parsed
    }

    func importLRC(from url: URL, for song: Song) -> [LyricLine]? {
        guard let lrc = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let lines = parseLRC(lrc)
        guard !lines.isEmpty else { return nil }
        save(lines, for: song)
        return lines
    }

    func lrcFileURL(for song: Song) -> URL {
        lyricsDirectory.appendingPathComponent("\(song.id.uuidString).lrc")
    }
}

// MARK: - LRCLIB Response

private struct LRCLIBResponse: Codable {
    let id: Int?
    let trackName: String?
    let artistName: String?
    let duration: Double?
    let syncedLyrics: String?
    let plainLyrics: String?
}
