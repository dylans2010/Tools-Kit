import Foundation
import ZIPFoundation

struct ZipExportService {
    enum Error: LocalizedError {
        case noFiles
        case creationFailed

        var errorDescription: String? {
            switch self {
            case .noFiles:
                return "No downloaded music files are available to export."
            case .creationFailed:
                return "Failed to create ZIP archive."
            }
        }
    }

    private var musicDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Music", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var exportsDirectory: URL {
        let dir = musicDirectory.appendingPathComponent("Exports", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func exportDownloadedFilesAsPlaylistZip(onProgress: (Double) -> Void) throws -> URL {
        let allowedExtensions: Set<String> = ["mp3", "mp4", "m4a", "aac", "wav", "flac"]
        let files = ((try? FileManager.default.contentsOfDirectory(
            at: musicDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? [])
            .filter { allowedExtensions.contains($0.pathExtension.lowercased()) }

        guard !files.isEmpty else {
            throw Error.noFiles
        }

        let zipURL = exportsDirectory.appendingPathComponent("playlist.zip")
        if FileManager.default.fileExists(atPath: zipURL.path) {
            try? FileManager.default.removeItem(at: zipURL)
        }

        guard let archive = Archive(url: zipURL, accessMode: .create) else {
            throw Error.creationFailed
        }

        for (index, file) in files.enumerated() {
            try archive.addEntry(with: file.lastPathComponent, relativeTo: musicDirectory)
            let progress = Double(index + 1) / Double(files.count)
            onProgress(progress)
        }

        return zipURL
    }
}
