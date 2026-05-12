import Foundation
import AVFoundation
import Combine

enum RadioPlaybackState: Equatable, Sendable {
    case idle
    case loading
    case playing
    case paused
    case error(String)
}

@MainActor
final class RadioPlayerManager: ObservableObject {
    nonisolated(unsafe) static let shared = RadioPlayerManager()

    @Published var currentStation: RadioStation?
    @Published var playbackState: RadioPlaybackState = .idle
    @Published var favorites: [RadioStation] = []
    @Published var recentlyPlayed: [RadioStation] = []

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var observers: Set<AnyCancellable> = []
    private var retryCount = 0
    private let maxRetries = 1

    private let favoritesKey = "radio.favorites"
    private let recentKey = "radio.recentlyPlayed"

    private init() {
        loadFavorites()
        loadRecentlyPlayed()
    }

    var isPlaying: Bool {
        if case .playing = playbackState { return true }
        return false
    }

    // MARK: - Playback

    func play(station: RadioStation) {
        guard let url = station.resolvedURL else {
            playbackState = .error("Invalid stream URL")
            InternalLogger.shared.log("RadioPlayer: Invalid URL for \"\(station.name)\"", level: .error)
            return
        }
        stop()
        currentStation = station
        playbackState = .loading
        retryCount = 0
        startPlayback(url: url, station: station)
    }

    func togglePlayPause() {
        switch playbackState {
        case .playing:
            player?.pause()
            playbackState = .paused
        case .paused:
            player?.play()
            playbackState = .playing
        case .idle, .error:
            if let station = currentStation { play(station: station) }
        default:
            break
        }
    }

    func stop() {
        observers.removeAll()
        player?.pause()
        player = nil
        playerItem = nil
        playbackState = .idle
    }

    // MARK: - Favorites

    func addFavorite(_ station: RadioStation) {
        guard !isFavorite(station) else { return }
        favorites.append(station)
        saveFavorites()
    }

    func removeFavorite(_ station: RadioStation) {
        favorites.removeAll { $0.stationuuid == station.stationuuid }
        saveFavorites()
    }

    func isFavorite(_ station: RadioStation) -> Bool {
        favorites.contains { $0.stationuuid == station.stationuuid }
    }

    func toggleFavorite(_ station: RadioStation) {
        isFavorite(station) ? removeFavorite(station) : addFavorite(station)
    }

    // MARK: - Private

    private func startPlayback(url: URL, station: RadioStation) {
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        self.playerItem = item

        let avPlayer = AVPlayer(playerItem: item)
        avPlayer.automaticallyWaitsToMinimizeStalling = true
        self.player = avPlayer

        item.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                if status == .failed {
                    self.handleFailure(station: station)
                }
            }
            .store(in: &observers)

        avPlayer.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                switch status {
                case .playing:
                    self.playbackState = .playing
                    self.recordRecentlyPlayed(station)
                case .waitingToPlayAtSpecifiedRate:
                    if self.playbackState != .paused { self.playbackState = .loading }
                case .paused:
                    if case .loading = self.playbackState { /* keep loading */ }
                @unknown default:
                    break
                }
            }
            .store(in: &observers)

        avPlayer.play()
    }

    private func handleFailure(station: RadioStation) {
        let msg = playerItem?.error?.localizedDescription ?? "Unknown error"
        InternalLogger.shared.log("RadioPlayer: Failed for \"\(station.name)\" — \(msg)", level: .error)

        if retryCount < maxRetries {
            retryCount += 1
            InternalLogger.shared.log(
                "RadioPlayer: Retrying \"\(station.name)\" (attempt \(retryCount))", level: .warning)
            stop()
            guard let url = station.resolvedURL else { return }
            currentStation = station
            playbackState = .loading
            startPlayback(url: url, station: station)
        } else {
            playbackState = .error("Stream unavailable")
            InternalLogger.shared.log(
                "RadioPlayer: Giving up on \"\(station.name)\" after \(maxRetries) retries", level: .error)
        }
    }

    private func recordRecentlyPlayed(_ station: RadioStation) {
        recentlyPlayed.removeAll { $0.stationuuid == station.stationuuid }
        recentlyPlayed.insert(station, at: 0)
        if recentlyPlayed.count > 20 { recentlyPlayed = Array(recentlyPlayed.prefix(20)) }
        saveRecentlyPlayed()
    }

    // MARK: - Persistence

    private func saveFavorites() {
        guard let data = try? JSONEncoder().encode(favorites) else { return }
        UserDefaults.standard.set(data, forKey: favoritesKey)
    }

    private func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey),
              let stations = try? JSONDecoder().decode([RadioStation].self, from: data) else { return }
        favorites = stations
    }

    private func saveRecentlyPlayed() {
        guard let data = try? JSONEncoder().encode(recentlyPlayed) else { return }
        UserDefaults.standard.set(data, forKey: recentKey)
    }

    private func loadRecentlyPlayed() {
        guard let data = UserDefaults.standard.data(forKey: recentKey),
              let stations = try? JSONDecoder().decode([RadioStation].self, from: data) else { return }
        recentlyPlayed = stations
    }
}
