import Foundation

actor DownloadManager {
    private var musicDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Music", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private let maxConcurrentDownloads = 3
    private let fileManager = FileManager.default

    func downloadAvailableTracks(from matches: [MatchedTrack], onProgress: @Sendable @escaping (String, URL?) -> Void) async -> [String: URL] {
        var saved: [String: URL] = [:]

        // Process in chunks to limit concurrency
        for start in stride(from: 0, to: matches.count, by: maxConcurrentDownloads) {
            let end = min(start + maxConcurrentDownloads, matches.count)
            let chunk = Array(matches[start..<end])

            await withTaskGroup(of: (String, URL?).self) { group in
                for match in chunk {
                    group.addTask {
                        let result = await self.downloadTrack(match)
                        return (match.id, result)
                    }
                }

                for await (id, url) in group {
                    if let url = url {
                        saved[id] = url
                    }
                    onProgress(id, url)
                }
            }
        }

        return saved
    }

    private func downloadTrack(_ match: MatchedTrack) async -> URL? {
        guard match.sourceType == .local,
              let sourceURLString = match.sourceURL,
              let sourceURL = URL(string: sourceURLString),
              sourceURL.isFileURL,
              fileManager.fileExists(atPath: sourceURL.path) else {
            return nil
        }

        let destinationURL = musicDirectory.appendingPathComponent("\(match.original.id).\(sourceURL.pathExtension)")

        // Resume/Integrity check: if file exists and has size > 0, consider it done
        if fileManager.fileExists(atPath: destinationURL.path) {
            if let attributes = try? fileManager.attributesOfItem(atPath: destinationURL.path),
               let size = attributes[.size] as? Int64, size > 0 {
                return destinationURL
            } else {
                // Corrupt or zero size, remove and retry
                try? fileManager.removeItem(at: destinationURL)
            }
        }

        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)

            // Verify integrity after copy
            let attributes = try fileManager.attributesOfItem(atPath: destinationURL.path)
            if let size = attributes[.size] as? Int64, size > 0 {
                // Register with MusicLibraryManager
                await MainActor.run {
                    MusicLibraryManager.shared.importSong(from: destinationURL)
                }
                return destinationURL
            } else {
                try? fileManager.removeItem(at: destinationURL)
                return nil
            }
        } catch {
            return nil
        }
    }

    func downloadedFiles() -> [URL] {
        let files = (try? fileManager.contentsOfDirectory(
            at: musicDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []

        let allowedExtensions: Set<String> = ["mp3", "mp4", "m4a", "aac", "wav", "flac"]
        return files.filter { allowedExtensions.contains($0.pathExtension.lowercased()) }
    }

    func hasDownloadedFiles() -> Bool {
        !downloadedFiles().isEmpty
    }
}
