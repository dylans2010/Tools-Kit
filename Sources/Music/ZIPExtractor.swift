import Foundation
import ZIPFoundation

/// ZIPExtractor wraps ZIPFoundation to extract audio files from a ZIP archive.
struct ZIPExtractor: Sendable {

    struct Entry: Sendable {
        let filename: String
        let data: Data
    }

    /// Extracts all entries from the ZIP archive at `url` that match the
    /// allowed audio file extensions, returning their data in memory.
    static func extract(from url: URL) -> [Entry] {
        guard let archive = try? Archive(url: url, accessMode: .read) else {
            return []
        }

        let allowed: Set<String> = ["mp3", "mp4", "m4a", "aac", "wav", "flac"]
        var entries: [Entry] = []

        for entry in archive {
            // Skip directories
            guard entry.type == .file else { continue }

            let ext = URL(fileURLWithPath: entry.path)
                .pathExtension
                .lowercased()
            guard allowed.contains(ext) else { continue }

            var entryData = Data()
            do {
                _ = try archive.extract(entry, consumer: { chunk in
                    entryData.append(chunk)
                })
                entries.append(Entry(filename: entry.path, data: entryData))
            } catch {
                print("ZIPExtractor: failed to extract \(entry.path): \(error)")
            }
        }

        return entries
    }
}
