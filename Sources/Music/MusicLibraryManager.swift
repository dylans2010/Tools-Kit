import Foundation
import AVFoundation
import ZIPFoundation
import CryptoKit

final class MusicLibraryManager: ObservableObject {
    static let shared = MusicLibraryManager()

    @Published var songs: [Song] = []
    @Published var playlists: [Playlist] = []

    private let songsKey = "music.songs"
    private let playlistsKey = "music.playlists"
    private let songIDsByPathKey = "music.songIDsByPath"
    private let allowedExtensions: Set<String> = ["mp3", "mp4", "m4a", "aac", "wav", "flac"]
    private static let backupDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH-mm-ss'Z'"
        return formatter
    }()

    private struct BackupSongRecord: Codable {
        let id: UUID
        let title: String
        let artist: String
        let duration: TimeInterval
        let artworkData: Data?
        let dateAdded: Date
        let playCount: Int
        let fileName: String
    }

    private struct BackupManifest: Codable {
        let version: Int
        let songs: [BackupSongRecord]
        let playlists: [Playlist]
    }

    private var musicDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Music", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private init() {
        load()
    }

    // MARK: - Single File Import

    func importSong(from sourceURL: URL) {
        importFile(from: sourceURL, data: nil)
    }

    private func importFile(from sourceURL: URL, data: Data?) {
        let preferredName = sourceURL.lastPathComponent
        let destURL = uniqueDestinationURL(for: preferredName)
        do {
            if let data = data {
                try data.write(to: destURL)
            } else {
                try FileManager.default.copyItem(at: sourceURL, to: destURL)
            }

            let song = extractMetadata(from: destURL)
            DispatchQueue.main.async {
                guard !self.songs.contains(where: { $0.fileURL.path == destURL.path }) else { return }
                self.songs.append(song)
                self.save()
            }
        } catch {
            print("MusicLibraryManager: import error \(error)")
        }
    }

    private func extractMetadata(from url: URL, preferredID: UUID? = nil) -> Song {
        let asset = AVURLAsset(url: url)
        var title = url.deletingPathExtension().lastPathComponent
        var artist = "Unknown Artist"
        var artworkData: Data?

        for item in asset.commonMetadata {
            switch item.commonKey {
            case .commonKeyTitle:
                if let v = item.value as? String { title = v }
            case .commonKeyArtist:
                if let v = item.value as? String { artist = v }
            case .commonKeyArtwork:
                if let v = item.value as? Data { artworkData = v }
            default:
                break
            }
        }

        var duration: TimeInterval = 0
        let d = CMTimeGetSeconds(asset.duration)
        if d.isFinite && d > 0 { duration = d }

        return Song(id: preferredID ?? stableSongID(for: url), title: title, artist: artist, duration: duration,
                    fileURL: url, artworkData: artworkData)
    }

    // MARK: - ZIP Import

    /// Imports all supported audio files from a ZIP archive.
    /// - Returns: The `Song` objects that were successfully imported.
    @discardableResult
    func importFromZIP(at url: URL) async -> [Song] {
        let entries = ZIPExtractor.extract(from: url)
        let allowed = Set(["mp3", "mp4", "m4a", "aac", "wav", "flac"])
        var imported: [Song] = []

        for entry in entries {
            let ext = URL(fileURLWithPath: entry.filename)
                .pathExtension
                .lowercased()
            guard allowed.contains(ext) else { continue }

            // Use only the last path component (avoid nested folder names)
            let filename = URL(fileURLWithPath: entry.filename).lastPathComponent
            guard !filename.isEmpty else { continue }

            let destURL = uniqueDestinationURL(for: filename)
            do {
                try entry.data.write(to: destURL)

                let song = extractMetadata(from: destURL)
                await MainActor.run {
                    guard !self.songs.contains(where: {
                        $0.fileURL.path == destURL.path
                    }) else { return }
                    self.songs.append(song)
                    self.save()
                    imported.append(song)
                }
            } catch {
                print("MusicLibraryManager: ZIP entry error \(entry.filename): \(error)")
            }
        }

        return imported
    }

    // MARK: - Delete

    func deleteSong(_ song: Song) {
        songs.removeAll { $0.id == song.id }
        playlists = playlists.map { pl in
            var p = pl
            p.songIDs.removeAll { $0 == song.id }
            return p
        }
        try? FileManager.default.removeItem(at: song.fileURL)
        save()
    }

    func clearLibrary() {
        for song in songs {
            try? FileManager.default.removeItem(at: song.fileURL)
        }
        songs = []
        playlists = []
        save()
    }

    // MARK: - Playlists

    func createPlaylist(name: String, songIDs: [UUID] = []) {
        let pl = Playlist(name: name, songIDs: songIDs)
        playlists.append(pl)
        save()
    }

    func renameSong(id: UUID, newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = songs.firstIndex(where: { $0.id == id }) else { return }
        songs[idx].title = trimmed
        save()
    }

    func updatePlaylist(_ playlist: Playlist) {
        if let idx = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[idx] = playlist
            save()
        }
    }

    func deletePlaylist(_ playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }
        save()
    }

    func songs(for playlist: Playlist) -> [Song] {
        playlist.songIDs.compactMap { id in songs.first { $0.id == id } }
    }

    func song(by id: UUID) -> Song? {
        songs.first { $0.id == id }
    }

    func incrementPlayCount(for song: Song) {
        if let idx = songs.firstIndex(where: { $0.id == song.id }) {
            songs[idx].playCount += 1
            save()
        }
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(songs) {
            UserDefaults.standard.set(data, forKey: songsKey)
        }
        let songIDsByPath = Dictionary(uniqueKeysWithValues: songs.map { ($0.fileURL.path, $0.id.uuidString) })
        UserDefaults.standard.set(songIDsByPath, forKey: songIDsByPathKey)
        if let data = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(data, forKey: playlistsKey)
        }
    }

    private func load() {
        _ = musicDirectory // ensure directory exists

        var persistedSongs: [Song] = []
        if let data = UserDefaults.standard.data(forKey: songsKey),
           let decoded = try? JSONDecoder().decode([Song].self, from: data) {
            persistedSongs = decoded.filter { FileManager.default.fileExists(atPath: $0.fileURL.path) }
        }

        let persistedIDsByPath = (UserDefaults.standard.dictionary(forKey: songIDsByPathKey) as? [String: String]) ?? [:]
        let songsByPath = Dictionary(uniqueKeysWithValues: persistedSongs.map { ($0.fileURL.path, $0) })
        let onDiskURLs = ((try? FileManager.default.contentsOfDirectory(
            at: musicDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []).filter { allowedExtensions.contains($0.pathExtension.lowercased()) }

        songs = onDiskURLs.map { fileURL in
            if let existing = songsByPath[fileURL.path] {
                return existing
            }
            let restoredID = persistedIDsByPath[fileURL.path].flatMap(UUID.init(uuidString:))
            return extractMetadata(from: fileURL, preferredID: restoredID ?? stableSongID(for: fileURL))
        }

        if let data = UserDefaults.standard.data(forKey: playlistsKey),
           let decoded = try? JSONDecoder().decode([Playlist].self, from: data) {
            let validSongIDs = Set(songs.map(\.id))
            playlists = decoded.map { playlist in
                var updated = playlist
                updated.songIDs = playlist.songIDs.filter { validSongIDs.contains($0) }
                if let artworkID = updated.artworkSongID, !validSongIDs.contains(artworkID) {
                    updated.artworkSongID = updated.songIDs.first
                }
                return updated
            }
        }
        save()
    }

    private func uniqueDestinationURL(for filename: String) -> URL {
        let sanitized = filename.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseName = URL(fileURLWithPath: sanitized).deletingPathExtension().lastPathComponent
        let ext = URL(fileURLWithPath: sanitized).pathExtension
        let fallbackBase = baseName.isEmpty ? "Imported Song" : baseName

        var candidate = musicDirectory.appendingPathComponent(sanitized.isEmpty ? "\(fallbackBase).mp3" : sanitized)
        if !FileManager.default.fileExists(atPath: candidate.path) {
            return candidate
        }

        var index = 1
        while true {
            let suffix = " (\(index))"
            let name = ext.isEmpty ? "\(fallbackBase)\(suffix)" : "\(fallbackBase)\(suffix).\(ext)"
            candidate = musicDirectory.appendingPathComponent(name)
            if !FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
            index += 1
        }
    }

    func createBackupArchive() throws -> URL {
        let stamp = Self.backupDateFormatter.string(from: Date())
        let backupURL = FileManager.default.temporaryDirectory.appendingPathComponent("ToolsKit-Music-Backup-\(stamp).zip")
        try? FileManager.default.removeItem(at: backupURL)
        guard let archive = Archive(url: backupURL, accessMode: .create) else {
            throw NSError(domain: "MusicLibraryBackup", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create backup archive. Check available storage and try again."])
        }

        var usedNames = Set<String>()
        var records: [BackupSongRecord] = []
        for song in songs where FileManager.default.fileExists(atPath: song.fileURL.path) {
            let backupFileName = uniqueBackupFileName(for: song.fileURL.lastPathComponent, usedNames: &usedNames)
            let data = try Data(contentsOf: song.fileURL)
            try addToArchive(data: data, atPath: "songs/\(backupFileName)", archive: archive)

            records.append(BackupSongRecord(
                id: song.id,
                title: song.title,
                artist: song.artist,
                duration: song.duration,
                artworkData: song.artworkData,
                dateAdded: song.dateAdded,
                playCount: song.playCount,
                fileName: backupFileName
            ))
        }

        let manifest = BackupManifest(version: 1, songs: records, playlists: playlists)
        let manifestData = try JSONEncoder().encode(manifest)
        try addToArchive(data: manifestData, atPath: "manifest.json", archive: archive)
        return backupURL
    }

    @discardableResult
    func restoreFromBackup(at url: URL) throws -> (songs: Int, playlists: Int) {
        guard let archive = Archive(url: url, accessMode: .read) else {
            throw NSError(domain: "MusicLibraryBackup", code: 2, userInfo: [NSLocalizedDescriptionKey: "The selected file could not be read as a ZIP archive. Please select a valid music backup file."])
        }

        guard let manifestEntry = archive["manifest.json"] else {
            throw NSError(domain: "MusicLibraryBackup", code: 3, userInfo: [NSLocalizedDescriptionKey: "Backup manifest is missing."])
        }
        let manifestData = try extractData(from: manifestEntry, archive: archive)
        let manifest = try JSONDecoder().decode(BackupManifest.self, from: manifestData)

        let existingFiles = (try? FileManager.default.contentsOfDirectory(at: musicDirectory, includingPropertiesForKeys: nil)) ?? []
        for fileURL in existingFiles {
            try? FileManager.default.removeItem(at: fileURL)
        }

        var restoredSongs: [Song] = []
        for record in manifest.songs {
            guard let songEntry = archive["songs/\(record.fileName)"] else { continue }
            let songData = try extractData(from: songEntry, archive: archive)
            let destination = uniqueDestinationURL(for: record.fileName)
            try songData.write(to: destination)

            var restored = extractMetadata(from: destination, preferredID: record.id)
            restored.title = record.title
            restored.artist = record.artist
            restored.duration = record.duration
            restored.artworkData = record.artworkData ?? restored.artworkData
            restored.dateAdded = record.dateAdded
            restored.playCount = record.playCount
            restoredSongs.append(restored)
        }

        songs = restoredSongs
        let validSongIDs = Set(restoredSongs.map(\.id))
        playlists = manifest.playlists.map { playlist in
            var updated = playlist
            updated.songIDs = playlist.songIDs.filter { validSongIDs.contains($0) }
            if let artworkID = updated.artworkSongID, !validSongIDs.contains(artworkID) {
                updated.artworkSongID = updated.songIDs.first
            }
            return updated
        }
        save()
        return (songs: songs.count, playlists: playlists.count)
    }

    /// Builds a deterministic UUID from a song file path so song IDs remain stable
    /// when metadata is reconstructed from on-disk files after app relaunches.
    /// SHA-256 is used to minimize collisions for different paths, then truncated to
    /// 16 bytes because UUID storage requires 128 bits.
    private func stableSongID(for url: URL) -> UUID {
        let normalizedPath = url.standardizedFileURL.path.lowercased()
        let digest = SHA256.hash(data: normalizedPath.utf8)
        var uuid = uuid_t()
        withUnsafeMutableBytes(of: &uuid) { destination in
            _ = destination.copyBytes(from: digest.prefix(16))
        }
        return UUID(uuid: uuid)
    }

    private func uniqueBackupFileName(for original: String, usedNames: inout Set<String>) -> String {
        let trimmed = original.trimmingCharacters(in: .whitespacesAndNewlines)
        let originalURL = URL(fileURLWithPath: trimmed.isEmpty ? "song.mp3" : trimmed)
        let ext = originalURL.pathExtension
        let base = originalURL.deletingPathExtension().lastPathComponent.isEmpty
            ? "song"
            : originalURL.deletingPathExtension().lastPathComponent

        var candidate = ext.isEmpty ? base : "\(base).\(ext)"
        var index = 1
        while usedNames.contains(candidate) {
            let suffix = " (\(index))"
            candidate = ext.isEmpty ? "\(base)\(suffix)" : "\(base)\(suffix).\(ext)"
            index += 1
        }
        usedNames.insert(candidate)
        return candidate
    }

    private func addToArchive(data: Data, atPath path: String, archive: Archive) throws {
        try archive.addEntry(with: path, type: .file, uncompressedSize: Int64(data.count), compressionMethod: .deflate) { position, size in
            let lowerBound = Int(position)
            let upperBound = min(lowerBound + size, data.count)
            return data.subdata(in: lowerBound..<upperBound)
        }
    }

    private func extractData(from entry: Archive.Entry, archive: Archive) throws -> Data {
        var result = Data()
        _ = try archive.extract(entry) { chunk in
            result.append(chunk)
        }
        return result
    }
}
