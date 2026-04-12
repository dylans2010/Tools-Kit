import Foundation
import AVFoundation

final class MusicLibraryManager: ObservableObject {
    static let shared = MusicLibraryManager()

    @Published var songs: [Song] = []
    @Published var playlists: [Playlist] = []

    private let songsKey = "music.songs"
    private let playlistsKey = "music.playlists"
    private let allowedExtensions: Set<String> = ["mp3", "mp4", "m4a", "aac", "wav", "flac"]

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

    private func extractMetadata(from url: URL) -> Song {
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

        return Song(title: title, artist: artist, duration: duration,
                    fileURL: url, artworkData: artworkData)
    }

    // MARK: - ZIP Import

    func importFromZIP(at url: URL) async {
        let entries = ZIPExtractor.extract(from: url)
        let allowed = Set(["mp3", "mp4", "m4a", "aac", "wav", "flac"])

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
                }
            } catch {
                print("MusicLibraryManager: ZIP entry error \(entry.filename): \(error)")
            }
        }
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
            return extractMetadata(from: fileURL)
        }

        if let data = UserDefaults.standard.data(forKey: playlistsKey),
           let decoded = try? JSONDecoder().decode([Playlist].self, from: data) {
            playlists = decoded
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
}
