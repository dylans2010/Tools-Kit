import Foundation

class SongDownloadAudio {
    func download(from url: URL, fileName: String) async throws -> URL {
        let (tempURL, _) = try await URLSession.shared.download(from: url)

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fallbackFolder = documentsURL.appendingPathComponent("FallbackFetch", isDirectory: true)

        if !FileManager.default.fileExists(atPath: fallbackFolder.path) {
            try FileManager.default.createDirectory(at: fallbackFolder, withIntermediateDirectories: true)
        }

        let destinationURL = fallbackFolder.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        try FileManager.default.moveItem(at: tempURL, to: destinationURL)
        return destinationURL
    }
}
