import Foundation

/// Converts LyricLine arrays into .lrc formatted strings
/// and writes them to the file system.
struct LRCExporterService: Sendable {

    // MARK: - String Conversion

    /// Converts an array of LyricLine into an .lrc formatted string.
    func lrcString(from lines: [LyricLine]) -> String {
        lines
            .sorted { $0.timestamp < $1.timestamp }
            .map { line in
                let m = Int(line.timestamp) / 60
                let s = line.timestamp.truncatingRemainder(dividingBy: 60)
                return String(format: "[%02d:%05.2f] %@", m, s, line.text)
            }
            .joined(separator: "\n")
    }

    // MARK: - File Export

    /// Writes the .lrc string to a temporary file and returns its URL,
    /// ready to be shared via UIActivityViewController.
    func exportToFile(lines: [LyricLine], songTitle: String) throws -> URL {
        let content = lrcString(from: lines)
        let safeName = songTitle
            .components(separatedBy: .init(charactersIn: "/\\:*?\"<>|"))
            .joined(separator: "_")
        let fileName = safeName.isEmpty ? "lyrics.lrc" : "\(safeName).lrc"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try content.write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
    }

    /// Writes the .lrc string to the app's Lyrics directory for a given song ID.
    func saveLocally(lines: [LyricLine], songID: String) throws {
        let dir = lyricsDirectory
        let url = dir.appendingPathComponent("\(songID).lrc")
        try lrcString(from: lines).write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Private

    private var lyricsDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Lyrics", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
