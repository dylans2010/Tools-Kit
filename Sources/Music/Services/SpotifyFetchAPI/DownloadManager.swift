import Foundation

actor DownloadManager {
    private var musicDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Music", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func downloadAvailableTracks(from matches: [MatchedTrack]) async -> [String: URL] {
        var saved: [String: URL] = [:]

        for match in matches {
            guard match.sourceType == .local,
                  let sourceURLString = match.sourceURL,
                  let sourceURL = URL(string: sourceURLString),
                  sourceURL.isFileURL,
                  sourceURL.pathExtension.lowercased() == "mp3",
                  FileManager.default.fileExists(atPath: sourceURL.path) else {
                continue
            }

            let destinationURL = musicDirectory.appendingPathComponent("\(match.original.id).mp3")
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                saved[match.id] = destinationURL
                continue
            }

            do {
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                saved[match.id] = destinationURL
            } catch {
                continue
            }
        }

        return saved
    }

    func downloadedFiles() -> [URL] {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: musicDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []

        return files.filter { $0.pathExtension.lowercased() == "mp3" }
    }

    func hasDownloadedFiles() -> Bool {
        !downloadedFiles().isEmpty
    }
}
