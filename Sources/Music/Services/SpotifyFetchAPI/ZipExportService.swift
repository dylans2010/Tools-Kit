import Foundation
import ZIPFoundation

struct ZipExportService {
    enum Error: LocalizedError {
        case noFiles
        case creationFailed

        var errorDescription: String? {
            switch self {
            case .noFiles:
                return "No downloaded MP3 files are available to export."
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

    func exportDownloadedFilesAsPlaylistZip() throws -> URL {
        let files = ((try? FileManager.default.contentsOfDirectory(
            at: musicDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? [])
            .filter { $0.pathExtension.lowercased() == "mp3" }

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

        for file in files {
            try archive.addEntry(with: file.lastPathComponent, relativeTo: musicDirectory)
        }

        return zipURL
    }
}
