import Foundation
import AVFoundation

final class MusicLibraryManager: ObservableObject {
    static let shared = MusicLibraryManager()

    @Published var songs: [Song] = []
    @Published var playlists: [Playlist] = []

    private let songsKey = "music.songs"
    private let playlistsKey = "music.playlists"

    private var musicDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Music", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private init() {
        load()
    }

    // MARK: - Import

    func importSong(from sourceURL: URL) {
        let destURL = musicDirectory.appendingPathComponent(sourceURL.lastPathComponent)
        do {
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destURL)

            let asset = AVURLAsset(url: destURL)
            var title = sourceURL.deletingPathExtension().lastPathComponent
            var artist = "Unknown Artist"
            var duration: TimeInterval = 0
            var artworkData: Data?

            for item in asset.commonMetadata {
                switch item.commonKey {
                case .commonKeyTitle:
                    if let val = item.value as? String { title = val }
                case .commonKeyArtist:
                    if let val = item.value as? String { artist = val }
                case .commonKeyArtwork:
                    if let val = item.value as? Data { artworkData = val }
                default:
                    break
                }
            }

            let cmDuration = asset.duration
            if cmDuration.timescale > 0 {
                duration = CMTimeGetSeconds(cmDuration)
            }

            let song = Song(title: title, artist: artist, duration: duration,
                            fileURL: destURL, artworkData: artworkData)
            DispatchQueue.main.async {
                self.songs.append(song)
                self.save()
            }
        } catch {
            print("MusicLibraryManager: import error \(error)")
        }
    }

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
        if let data = UserDefaults.standard.data(forKey: songsKey),
           let decoded = try? JSONDecoder().decode([Song].self, from: data) {
            songs = decoded.filter { FileManager.default.fileExists(atPath: $0.fileURL.path) }
        }
        if let data = UserDefaults.standard.data(forKey: playlistsKey),
           let decoded = try? JSONDecoder().decode([Playlist].self, from: data) {
            playlists = decoded
        }
    }
}
