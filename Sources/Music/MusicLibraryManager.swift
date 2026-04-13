import Foundation
import AVFoundation
import ZIPFoundation
import CryptoKit

final class MusicLibraryManager: ObservableObject {
    static let shared = MusicLibraryManager()

    @Published var songs: [Song] = []
    @Published var playlists: [Playlist] = []

    // UserDefaults keys (used only for general / non-folder songs and legacy playlists).
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

    // MARK: - Metadata JSON (per-playlist folder)

    private struct PlaylistMetadata: Codable {
        var playlistName: String
        var songs: [SongMeta]

        struct SongMeta: Codable {
            var title: String
            var fileName: String
        }
    }

    // MARK: - Backup helpers

    private struct BackupSongRecord: Codable {
        let id: UUID
        let title: String
        let artist: String
        let duration: TimeInterval
        let artworkData: Data?
        let dateAdded: Date
        let playCount: Int
        let fileName: String
        let playlistName: String?
    }

    private struct BackupManifest: Codable {
        let version: Int
        let songs: [BackupSongRecord]
        let playlists: [Playlist]
    }

    // MARK: - Directory helpers

    /// Root music directory: Documents/Music/
    private var musicDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Music", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Sanitise a string so it is safe to use as a directory / file name.
    /// Also strips parent-directory traversal sequences to prevent path escape.
    private func sanitizeFilename(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\:*?\"<>|")
        var sanitized = name
            .components(separatedBy: invalid)
            .joined(separator: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        // Replace any parent-directory references regardless of encoding.
        sanitized = sanitized.replacingOccurrences(of: "..", with: "_")
        return String(sanitized.prefix(100))
    }

    /// Returns a unique folder URL under musicDirectory for the given playlist name.
    /// If the folder already exists, a timestamp suffix is appended.
    private func uniquePlaylistFolderURL(for name: String) -> URL {
        let base = sanitizeFilename(name)
        let safeName = base.isEmpty ? "Playlist" : base
        let candidate = musicDirectory.appendingPathComponent(safeName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: candidate.path) {
            return candidate
        }
        let stamp = Int(Date().timeIntervalSince1970)
        return musicDirectory.appendingPathComponent("\(safeName)_\(stamp)", isDirectory: true)
    }

    /// Returns a unique file URL inside `folderURL` for the given filename.
    private func uniqueFileURL(in folderURL: URL, for filename: String) -> URL {
        let sanitized = sanitizeFilename(filename)
        let fileURL = URL(fileURLWithPath: sanitized.isEmpty ? "song.mp3" : sanitized)
        let base = fileURL.deletingPathExtension().lastPathComponent
        let ext = fileURL.pathExtension

        var candidate = folderURL.appendingPathComponent(sanitized.isEmpty ? "song.mp3" : sanitized)
        if !FileManager.default.fileExists(atPath: candidate.path) { return candidate }

        var index = 1
        while true {
            let newName = ext.isEmpty ? "\(base) (\(index))" : "\(base) (\(index)).\(ext)"
            candidate = folderURL.appendingPathComponent(newName)
            if !FileManager.default.fileExists(atPath: candidate.path) { return candidate }
            index += 1
        }
    }

    // MARK: - Init

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

    private func extractMetadata(from url: URL, preferredID: UUID? = nil, playlistName: String? = nil) -> Song {
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
                    fileURL: url, artworkData: artworkData, playlistName: playlistName)
    }

    // MARK: - ZIP Import (folder-based)

    /// Imports all supported audio files from a ZIP archive into a dedicated playlist folder.
    /// Creates Documents/Music/{playlistName}/, copies all audio files there, and writes metadata.json.
    /// - Returns: The newly created `Playlist`, or `nil` if no audio files were found.
    @discardableResult
    func importFromZIP(at url: URL, playlistName: String) async -> Playlist? {
        let folderURL = uniquePlaylistFolderURL(for: playlistName.isEmpty ? "Imported Playlist" : playlistName)
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        } catch {
            print("MusicLibraryManager: failed to create playlist folder: \(error)")
            return nil
        }

        let entries = ZIPExtractor.extract(from: url)
        let allowed: Set<String> = ["mp3", "mp4", "m4a", "aac", "wav", "flac"]
        let actualName = folderURL.lastPathComponent
        var importedSongs: [Song] = []

        for entry in entries {
            let ext = URL(fileURLWithPath: entry.filename).pathExtension.lowercased()
            guard allowed.contains(ext) else { continue }

            let rawName = URL(fileURLWithPath: entry.filename).lastPathComponent
            guard !rawName.isEmpty else { continue }

            let destURL = uniqueFileURL(in: folderURL, for: rawName)
            do {
                try entry.data.write(to: destURL)
                let song = extractMetadata(from: destURL, playlistName: actualName)
                importedSongs.append(song)
            } catch {
                print("MusicLibraryManager: ZIP entry error \(entry.filename): \(error)")
            }
        }

        if importedSongs.isEmpty {
            try? FileManager.default.removeItem(at: folderURL)
            return nil
        }

        let playlist = Playlist(name: actualName, songIDs: importedSongs.map(\.id), folderURL: folderURL)
        writeMetadata(for: playlist, songs: importedSongs)

        await MainActor.run {
            for song in importedSongs {
                guard !self.songs.contains(where: { $0.fileURL.path == song.fileURL.path }) else { continue }
                self.songs.append(song)
            }
            self.playlists.append(playlist)
            self.save()
        }

        return playlist
    }

    // MARK: - Delete

    func deleteSong(_ song: Song) {
        songs.removeAll { $0.id == song.id }
        playlists = playlists.map { pl in
            var p = pl
            p.songIDs.removeAll { $0 == song.id }
            // Update metadata.json for folder-based playlists
            if p.folderURL != nil { writeMetadata(for: p, songs: songs(for: p)) }
            return p
        }
        try? FileManager.default.removeItem(at: song.fileURL)
        save()
    }

    func clearLibrary() {
        // Remove all playlist folders
        for playlist in playlists {
            if let url = playlist.folderURL {
                try? FileManager.default.removeItem(at: url)
            }
        }
        // Remove remaining songs in root directory
        for song in songs where song.playlistName == nil {
            try? FileManager.default.removeItem(at: song.fileURL)
        }
        songs = []
        playlists = []
        save()
    }

    // MARK: - Playlists

    @discardableResult
    func createPlaylist(name: String, songIDs: [UUID] = []) -> Playlist {
        let folderURL = uniquePlaylistFolderURL(for: name.isEmpty ? "Playlist" : name)
        try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        let actualName = folderURL.lastPathComponent
        let pl = Playlist(name: actualName, songIDs: songIDs, folderURL: folderURL)
        writeMetadata(for: pl, songs: songs(for: pl))
        playlists.append(pl)
        save()
        return pl
    }

    func renameSong(id: UUID, newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = songs.firstIndex(where: { $0.id == id }) else { return }
        songs[idx].title = trimmed
        // Update metadata.json if the song belongs to a playlist folder
        if let name = songs[idx].playlistName,
           let playlist = playlists.first(where: { $0.name == name }) {
            writeMetadata(for: playlist, songs: songs(for: playlist))
        }
        save()
    }

    func updatePlaylist(_ playlist: Playlist) {
        if let idx = playlists.firstIndex(where: { $0.id == playlist.id }) {
            // Preserve the folderURL from the existing entry in case the caller
            // passed a value-type copy that lost the folderURL property.
            let existingFolderURL = playlists[idx].folderURL
            playlists[idx] = playlist
            if playlists[idx].folderURL == nil {
                playlists[idx].folderURL = existingFolderURL
            }
            writeMetadata(for: playlists[idx], songs: songs(for: playlists[idx]))
            save()
        }
    }

    func deletePlaylist(_ playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }
        if let folderURL = playlist.folderURL {
            // Remove all in-memory songs that belong to this playlist folder
            songs.removeAll { $0.playlistName == playlist.name }
            // Remove the physical folder (and all its contents)
            try? FileManager.default.removeItem(at: folderURL)
        }
        save()
    }

    func songs(for playlist: Playlist) -> [Song] {
        playlist.songIDs.compactMap { id in songs.first { $0.id == id } }
    }

    /// Removes a song from a playlist.
    /// For folder-based playlists the song's file is also deleted from the playlist folder
    /// when the song was originally imported into it (song.playlistName == playlist.name).
    func removeSong(_ song: Song, fromPlaylist playlist: Playlist) {
        if let idx = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[idx].songIDs.removeAll { $0 == song.id }
            if playlists[idx].folderURL != nil, song.playlistName == playlist.name {
                // The song file lives inside the playlist folder – delete it.
                try? FileManager.default.removeItem(at: song.fileURL)
                songs.removeAll { $0.id == song.id }
                writeMetadata(for: playlists[idx], songs: songs(for: playlists[idx]))
            }
        }
        save()
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

    // MARK: - Metadata JSON

    private func writeMetadata(for playlist: Playlist, songs songList: [Song]? = nil) {
        guard let folderURL = playlist.folderURL else { return }
        let list = songList ?? songs(for: playlist)
        let songMetas = list.map { PlaylistMetadata.SongMeta(title: $0.title, fileName: $0.fileURL.lastPathComponent) }
        let meta = PlaylistMetadata(playlistName: playlist.name, songs: songMetas)
        guard let data = try? JSONEncoder().encode(meta) else { return }
        let metaURL = folderURL.appendingPathComponent("metadata.json")
        try? data.write(to: metaURL, options: .atomic)
    }

    // MARK: - Persistence

    private func save() {
        // Persist only general (non-folder) songs to UserDefaults.
        let generalSongs = songs.filter { $0.playlistName == nil }
        if let data = try? JSONEncoder().encode(generalSongs) {
            UserDefaults.standard.set(data, forKey: songsKey)
        }
        let songIDsByPath = Dictionary(uniqueKeysWithValues: generalSongs.map { ($0.fileURL.path, $0.id.uuidString) })
        UserDefaults.standard.set(songIDsByPath, forKey: songIDsByPathKey)

        // Persist only legacy (non-folder) playlists to UserDefaults.
        let legacyPlaylists = playlists.filter { $0.folderURL == nil }
        if let data = try? JSONEncoder().encode(legacyPlaylists) {
            UserDefaults.standard.set(data, forKey: playlistsKey)
        }

        // Write metadata.json for every folder-based playlist.
        for playlist in playlists where playlist.folderURL != nil {
            writeMetadata(for: playlist)
        }
    }

    private func load() {
        _ = musicDirectory // ensure root exists

        // --- Scan Documents/Music/ for playlist sub-folders and general songs ---
        let topContents = (try? FileManager.default.contentsOfDirectory(
            at: musicDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        var rootAudioURLs: [URL] = []
        var playlistFolderURLs: [URL] = []

        for item in topContents {
            let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDir {
                playlistFolderURLs.append(item)
            } else if allowedExtensions.contains(item.pathExtension.lowercased()) {
                rootAudioURLs.append(item)
            }
        }

        // Load folder-based playlists from disk.
        var diskPlaylists: [Playlist] = []
        var diskSongs: [Song] = []
        for folderURL in playlistFolderURLs {
            if let (playlist, pSongs) = loadPlaylistFromFolder(folderURL) {
                diskPlaylists.append(playlist)
                diskSongs.append(contentsOf: pSongs)
            }
        }

        // Load general songs (root directory) from UserDefaults + disk.
        let persistedIDsByPath = (UserDefaults.standard.dictionary(forKey: songIDsByPathKey) as? [String: String]) ?? [:]
        var persistedByPath: [String: Song] = [:]
        if let data = UserDefaults.standard.data(forKey: songsKey),
           let decoded = try? JSONDecoder().decode([Song].self, from: data) {
            for s in decoded where FileManager.default.fileExists(atPath: s.fileURL.path) {
                persistedByPath[s.fileURL.path] = s
            }
        }

        let rootSongs = rootAudioURLs.map { fileURL -> Song in
            if let existing = persistedByPath[fileURL.path] { return existing }
            let restoredID = persistedIDsByPath[fileURL.path].flatMap(UUID.init(uuidString:))
            return extractMetadata(from: fileURL, preferredID: restoredID ?? stableSongID(for: fileURL))
        }

        // Merge all songs.
        songs = rootSongs + diskSongs

        // Load legacy playlists from UserDefaults; skip any whose name is already backed by a folder.
        let folderPlaylistNames = Set(diskPlaylists.map(\.name))
        var legacyPlaylists: [Playlist] = []
        if let data = UserDefaults.standard.data(forKey: playlistsKey),
           let decoded = try? JSONDecoder().decode([Playlist].self, from: data) {
            let validIDs = Set(songs.map(\.id))
            legacyPlaylists = decoded
                .filter { !folderPlaylistNames.contains($0.name) }
                .map { pl in
                    var updated = pl
                    updated.songIDs = pl.songIDs.filter { validIDs.contains($0) }
                    if let aID = updated.artworkSongID, !validIDs.contains(aID) {
                        updated.artworkSongID = updated.songIDs.first
                    }
                    return updated
                }
        }

        playlists = diskPlaylists + legacyPlaylists
        save()
    }

    /// Loads a playlist from a folder under Documents/Music/.
    /// Reads metadata.json when present; falls back to scanning audio files.
    private func loadPlaylistFromFolder(_ folderURL: URL) -> (Playlist, [Song])? {
        let playlistName = folderURL.lastPathComponent
        let metadataURL = folderURL.appendingPathComponent("metadata.json")

        var songMetas: [PlaylistMetadata.SongMeta] = []
        if let data = try? Data(contentsOf: metadataURL),
           let meta = try? JSONDecoder().decode(PlaylistMetadata.self, from: data) {
            songMetas = meta.songs
        }

        let fileURLs = ((try? FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []).filter { allowedExtensions.contains($0.pathExtension.lowercased()) }

        guard !fileURLs.isEmpty else { return nil }

        let metaByFilename: [String: PlaylistMetadata.SongMeta] = Dictionary(
            songMetas.map { ($0.fileName, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let metaOrder = songMetas.map(\.fileName)

        var loadedSongs: [Song] = fileURLs.map { fileURL -> Song in
            var song = extractMetadata(from: fileURL,
                                       preferredID: stableSongID(for: fileURL),
                                       playlistName: playlistName)
            if let meta = metaByFilename[fileURL.lastPathComponent], !meta.title.isEmpty {
                song.title = meta.title
            }
            return song
        }

        // Preserve metadata order when available.
        if !metaOrder.isEmpty {
            loadedSongs.sort { a, b in
                let ai = metaOrder.firstIndex(of: a.fileURL.lastPathComponent) ?? Int.max
                let bi = metaOrder.firstIndex(of: b.fileURL.lastPathComponent) ?? Int.max
                return ai < bi
            }
        }

        let playlist = Playlist(name: playlistName,
                                songIDs: loadedSongs.map(\.id),
                                folderURL: folderURL)
        return (playlist, loadedSongs)
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
        guard let archive = try? Archive(url: backupURL, accessMode: .create) else {
            throw NSError(domain: "MusicLibraryBackup", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create backup archive. Check available storage and try again."])
        }

        var usedNames = Set<String>()
        var records: [BackupSongRecord] = []
        for song in songs where FileManager.default.fileExists(atPath: song.fileURL.path) {
            let backupFileName = uniqueBackupFileName(for: song.fileURL.lastPathComponent, usedNames: &usedNames)
            let data = try Data(contentsOf: song.fileURL)
            let archivePath = song.playlistName.map { "playlists/\($0)/\(backupFileName)" } ?? "songs/\(backupFileName)"
            try addToArchive(data: data, atPath: archivePath, archive: archive)

            records.append(BackupSongRecord(
                id: song.id,
                title: song.title,
                artist: song.artist,
                duration: song.duration,
                artworkData: song.artworkData,
                dateAdded: song.dateAdded,
                playCount: song.playCount,
                fileName: backupFileName,
                playlistName: song.playlistName
            ))
        }

        let manifest = BackupManifest(version: 1, songs: records, playlists: playlists)
        let manifestData = try JSONEncoder().encode(manifest)
        try addToArchive(data: manifestData, atPath: "manifest.json", archive: archive)
        return backupURL
    }

    @discardableResult
    func restoreFromBackup(at url: URL) throws -> (songs: Int, playlists: Int) {
        guard let archive = try? Archive(url: url, accessMode: .read) else {
            throw NSError(domain: "MusicLibraryBackup", code: 2, userInfo: [NSLocalizedDescriptionKey: "The selected file could not be read as a ZIP archive. Please select a valid music backup file."])
        }

        guard let manifestEntry = archive["manifest.json"] else {
            throw NSError(domain: "MusicLibraryBackup", code: 3, userInfo: [NSLocalizedDescriptionKey: "Backup manifest is missing."])
        }
        let manifestData = try extractData(from: manifestEntry, archive: archive)
        let manifest = try JSONDecoder().decode(BackupManifest.self, from: manifestData)

        // Remove existing library
        for playlist in playlists {
            if let folderURL = playlist.folderURL {
                try? FileManager.default.removeItem(at: folderURL)
            }
        }
        let rootFiles = (try? FileManager.default.contentsOfDirectory(at: musicDirectory, includingPropertiesForKeys: nil)) ?? []
        for fileURL in rootFiles where allowedExtensions.contains(fileURL.pathExtension.lowercased()) {
            try? FileManager.default.removeItem(at: fileURL)
        }

        // Pre-create playlist folders so all songs in the same playlist share the same folder URL.
        // Track actual folder URLs keyed by playlist name to avoid timestamp collisions.
        var restoredFoldersByName: [String: URL] = [:]
        for record in manifest.songs where record.playlistName != nil {
            let pName = record.playlistName!
            if restoredFoldersByName[pName] == nil {
                let folderURL = uniquePlaylistFolderURL(for: pName)
                try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
                restoredFoldersByName[pName] = folderURL
            }
        }

        // Restore songs
        var restoredSongs: [Song] = []
        for record in manifest.songs {
            let archivePath: String
            if let pName = record.playlistName {
                archivePath = "playlists/\(pName)/\(record.fileName)"
            } else {
                archivePath = "songs/\(record.fileName)"
            }
            // Also try legacy path without playlist prefix
            let entry = archive[archivePath] ?? archive["songs/\(record.fileName)"]
            guard let songEntry = entry else { continue }
            let songData = try extractData(from: songEntry, archive: archive)

            let destination: URL
            if let pName = record.playlistName, let folderURL = restoredFoldersByName[pName] {
                destination = uniqueFileURL(in: folderURL, for: record.fileName)
            } else {
                destination = uniqueDestinationURL(for: record.fileName)
            }
            try songData.write(to: destination)

            var restored = extractMetadata(from: destination, preferredID: record.id, playlistName: record.playlistName)
            restored.title = record.title
            restored.artist = record.artist
            restored.duration = record.duration
            restored.artworkData = record.artworkData ?? restored.artworkData
            restored.dateAdded = record.dateAdded
            restored.playCount = record.playCount
            restoredSongs.append(restored)
        }

        songs = restoredSongs

        // Restore playlists, re-attaching the actual folderURL for folder-based ones.
        let validIDs = Set(restoredSongs.map(\.id))
        playlists = manifest.playlists.map { pl in
            var updated = pl
            updated.songIDs = pl.songIDs.filter { validIDs.contains($0) }
            if let aID = updated.artworkSongID, !validIDs.contains(aID) {
                updated.artworkSongID = updated.songIDs.first
            }
            // Re-attach the actual restored folder URL (may have a timestamp suffix).
            updated.folderURL = restoredFoldersByName[pl.name]
            return updated
        }

        for playlist in playlists {
            writeMetadata(for: playlist)
        }
        save()
        return (songs: songs.count, playlists: playlists.count)
    }

    /// Builds a deterministic UUID from a song file path so song IDs remain stable
    /// when metadata is reconstructed from on-disk files after app relaunches.
    private func stableSongID(for url: URL) -> UUID {
        let normalizedPath = url.standardizedFileURL.path.lowercased()
        let digest = SHA256.hash(data: Data(normalizedPath.utf8))
        var uuid: uuid_t = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        withUnsafeMutableBytes(of: &uuid) { destination in
            _ = destination.copyBytes(from: [UInt8](digest.prefix(16)))
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

    private func extractData(from entry: Entry, archive: Archive) throws -> Data {
        var result = Data()
        _ = try archive.extract(entry) { chunk in
            result.append(chunk)
        }
        return result
    }
}

