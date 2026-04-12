import Foundation

/// Parses raw .lrc text into an array of LyricLine objects.
/// Supports [mm:ss.xx] format, multiple timestamps per line,
/// and silently skips invalid or malformed lines.
struct LRCParserService {

    /// Parse a full .lrc string into sorted LyricLine array.
    func parse(_ lrc: String) -> [LyricLine] {
        var lines: [LyricLine] = []
        for raw in lrc.components(separatedBy: "\n") {
            lines.append(contentsOf: parseLine(raw))
        }
        return lines.sorted { $0.timestamp < $1.timestamp }
    }

    // MARK: - Private

    private func parseLine(_ raw: String) -> [LyricLine] {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }

        var remaining = trimmed
        var timestamps: [TimeInterval] = []

        // Extract all [mm:ss.xx] tags at the start of the string
        while remaining.hasPrefix("[") {
            guard let closeRange = remaining.range(of: "]") else { break }
            let tagContent = String(remaining[remaining.index(after: remaining.startIndex)..<closeRange.lowerBound])
            remaining = String(remaining[closeRange.upperBound...]).trimmingCharacters(in: .whitespaces)

            if let ts = parseTimestamp(tagContent) {
                timestamps.append(ts)
            }
        }

        guard !timestamps.isEmpty, !remaining.isEmpty else { return [] }

        return timestamps.map { LyricLine(timestamp: $0, text: remaining) }
    }

    private func parseTimestamp(_ str: String) -> TimeInterval? {
        // Accepts mm:ss.xx or mm:ss
        let parts = str.split(separator: ":").map(String.init)
        guard parts.count == 2,
              let minutes = Double(parts[0]),
              let seconds = Double(parts[1]) else { return nil }
        guard minutes >= 0, seconds >= 0, seconds < 60 else { return nil }
        return minutes * 60 + seconds
    }
}
