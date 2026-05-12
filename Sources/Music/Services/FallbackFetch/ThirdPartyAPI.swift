import Foundation

struct MP3Result: Sendable {
    let title: String
    let url: String
    let bitrate: Int
    let size: String
}

struct ThirdPartyAPI: Sendable {
    /// Accepts a full YouTube URL, extracts the video ID, calls the
    /// download-lagu-mp3 API, and returns the highest-bitrate download link.
    static func getMP3Links(videoUrl: String) async throws -> MP3Result {
        // Extract the 11-character video ID
        let pattern = #"(?:v=|\/)([a-zA-Z0-9_-]{11})"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                  in: videoUrl,
                  range: NSRange(videoUrl.startIndex..., in: videoUrl)
              ),
              let range = Range(match.range(at: 1), in: videoUrl) else {
            throw ThirdPartyAPIError.invalidURL("Could not extract a YouTube video ID from the provided URL.")
        }
        let videoID = String(videoUrl[range])

        // Build request – no auth headers required
        let endpoint = "https://api.download-lagu-mp3.com/@api/json/mp3/\(videoID)"
        guard let url = URL(string: endpoint) else {
            throw ThirdPartyAPIError.invalidURL("Constructed API URL is invalid.")
        }
        let request = URLRequest(url: url)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ThirdPartyAPIError.fetchFailed("Network request failed: \(error.localizedDescription)")
        }

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ThirdPartyAPIError.fetchFailed("API returned a non-success HTTP status code.")
        }

        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let vidTitle = json["vidTitle"] as? String,
              let vidInfo = json["vidInfo"] as? [String: Any],
              !vidInfo.isEmpty else {
            throw ThirdPartyAPIError.noResults("The API returned no download links for this video.")
        }

        // Collect entries
        struct Entry: Sendable {
            let dloadUrl: String
            let bitrate: Int
            let mp3size: String
        }

        var entries: [Entry] = []
        for (_, value) in vidInfo {
            guard let item = value as? [String: Any],
                  let dloadUrl = item["dloadUrl"] as? String,
                  let mp3size = item["mp3size"] as? String else { continue }

            let bitrate: Int
            if let b = item["bitrate"] as? Int {
                bitrate = b
            } else if let b = item["bitrate"] as? Double {
                bitrate = Int(b)
            } else {
                continue
            }
            entries.append(Entry(dloadUrl: dloadUrl, bitrate: bitrate, mp3size: mp3size))
        }

        guard !entries.isEmpty else {
            throw ThirdPartyAPIError.noResults("No usable download entries found in the API response.")
        }

        // Prefer highest bitrate in order: 320 → 256 → 192 → 128 → 64
        let preferredBitrates = [320, 256, 192, 128, 64]
        var best: Entry?
        for preferred in preferredBitrates {
            if let found = entries.first(where: { $0.bitrate == preferred }) {
                best = found
                break
            }
        }
        if best == nil {
            best = entries.sorted { $0.bitrate > $1.bitrate }.first
        }

        guard let bestEntry = best else {
            throw ThirdPartyAPIError.noResults("Could not determine the best download link.")
        }

        return MP3Result(
            title: vidTitle,
            url: bestEntry.dloadUrl,
            bitrate: bestEntry.bitrate,
            size: bestEntry.mp3size
        )
    }
}

enum ThirdPartyAPIError: LocalizedError, Sendable {
    case invalidURL(String)
    case fetchFailed(String)
    case noResults(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let msg): return msg
        case .fetchFailed(let msg): return msg
        case .noResults(let msg): return msg
        }
    }
}
