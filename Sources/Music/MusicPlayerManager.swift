import Foundation
import AVFoundation
import MediaPlayer
import Combine
import UIKit

enum RepeatMode: String, CaseIterable {
    case off, one, all
}

final class MusicPlayerManager: ObservableObject {
    static let shared = MusicPlayerManager()

    // MARK: - Published state
    @Published var currentSong: Song?
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var queue: [Song] = []
    @Published var currentIndex: Int = 0
    @Published var shuffleEnabled: Bool = false
    @Published var repeatMode: RepeatMode = .off
    @Published var sleepTimerEndDate: Date?

    // MARK: - Private
    private let audioEngine = AudioEngineManager.shared
    private var originalQueue: [Song] = []
    private var sleepTimerTimer: Timer?
    private var wasPlayingBeforeInterruption = false
    private let queueIDsKey = "music.player.queueIDs"
    private let currentIndexKey = "music.player.currentIndex"
    private let currentSongIDKey = "music.player.currentSongID"
    private let shuffleKey = "music.player.shuffleEnabled"
    private let repeatModeKey = "music.player.repeatMode"

    private init() {
        setupAudioSession()
        setupEngineCallbacks()
        setupRemoteCommands()
        setupNotifications()
        restorePlaybackState()
    }

    // MARK: - Audio Session

    func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("MusicPlayerManager: AVAudioSession error \(error)")
        }
    }

    // MARK: - Engine Callbacks

    private func setupEngineCallbacks() {
        audioEngine.onTrackFinished = { [weak self] in
            self?.handleSongEnd()
        }
        audioEngine.onTimeUpdate = { [weak self] time in
            guard let self else { return }
            self.currentTime = time
            if self.duration > 0 { self.updateNowPlayingInfo() }
        }
    }

    // MARK: - Playback Control

    func play(song: Song, queue: [Song] = [], startIndex: Int = 0) {
        let providedQueue = queue.isEmpty ? [song] : queue
        let playableQueue = providedQueue.filter {
            $0.fileURL.isFileURL && FileManager.default.fileExists(atPath: $0.fileURL.path)
        }
        guard !playableQueue.isEmpty else { return }

        let clampedIndex = min(max(startIndex, 0), max(0, playableQueue.count - 1))
        let resolvedSong = playableQueue.first(where: { $0.id == song.id }) ?? playableQueue[clampedIndex]

        originalQueue = playableQueue
        self.queue = shuffleEnabled ? shuffled(from: playableQueue, keeping: resolvedSong) : playableQueue
        currentIndex = self.queue.firstIndex(where: { $0.id == resolvedSong.id }) ?? 0
        load(song: self.queue[currentIndex])
        savePlaybackState()
    }

    func play() {
        audioEngine.resume()
        isPlaying = true
        updateNowPlayingInfo()
    }

    func pause() {
        audioEngine.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func next() {
        guard !queue.isEmpty else { return }
        switch repeatMode {
        case .one:
            seek(to: 0)
            if !isPlaying { play() }
        case .all:
            currentIndex = (currentIndex + 1) % queue.count
            load(song: queue[currentIndex])
        case .off:
            let next = currentIndex + 1
            if next < queue.count {
                currentIndex = next
                load(song: queue[next])
            } else {
                pause()
                seek(to: 0)
            }
        }
    }

    func previous() {
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        guard !queue.isEmpty else { return }
        currentIndex = max(currentIndex - 1, 0)
        load(song: queue[currentIndex])
    }

    func seek(to time: TimeInterval) {
        audioEngine.seek(to: time)
        currentTime = time
        updateNowPlayingInfo()
    }

    // MARK: - Queue Management

    func addToQueue(_ song: Song) {
        guard song.fileURL.isFileURL, FileManager.default.fileExists(atPath: song.fileURL.path) else { return }
        queue.append(song)
        originalQueue.append(song)
        savePlaybackState()
    }

    func removeFromQueue(at offsets: IndexSet) {
        var adjusted = currentIndex
        for idx in offsets.sorted(by: >) {
            if idx < currentIndex { adjusted -= 1 }
        }
        queue.remove(atOffsets: offsets)
        originalQueue = queue
        currentIndex = adjusted
        savePlaybackState()
    }

    func moveInQueue(from source: IndexSet, to destination: Int) {
        queue.move(fromOffsets: source, toOffset: destination)
        originalQueue = queue
        if let song = currentSong, let newIdx = queue.firstIndex(where: { $0.id == song.id }) {
            currentIndex = newIdx
        }
        savePlaybackState()
    }

    func toggleShuffle() {
        shuffleEnabled.toggle()
        if shuffleEnabled {
            queue = shuffled(from: originalQueue, keeping: currentSong)
        } else {
            queue = originalQueue
        }
        if let song = currentSong, let idx = queue.firstIndex(where: { $0.id == song.id }) {
            currentIndex = idx
        }
        savePlaybackState()
    }

    func setRepeatMode(_ mode: RepeatMode) {
        repeatMode = mode
        savePlaybackState()
    }

    // MARK: - Sleep Timer

    func setSleepTimer(minutes: Int) {
        sleepTimerTimer?.invalidate()
        guard minutes > 0 else {
            sleepTimerEndDate = nil
            return
        }
        let interval = TimeInterval(minutes * 60)
        sleepTimerEndDate = Date().addingTimeInterval(interval)
        sleepTimerTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.pause()
            self?.sleepTimerEndDate = nil
        }
    }

    func resetPlaybackState() {
        sleepTimerTimer?.invalidate()
        sleepTimerTimer = nil
        audioEngine.stop()
        currentSong = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        queue = []
        originalQueue = []
        currentIndex = 0
        sleepTimerEndDate = nil
        updateNowPlayingInfo()
        savePlaybackState()
    }

    // MARK: - Private helpers

    private func load(song: Song) {
        guard song.fileURL.isFileURL, FileManager.default.fileExists(atPath: song.fileURL.path) else {
            pause()
            return
        }
        currentSong = song
        duration = song.duration
        currentTime = 0
        isPlaying = true

        audioEngine.play(url: song.fileURL)

        // Schedule crossfade to next track if enabled
        if audioEngine.crossfadeEnabled {
            let nextIdx: Int?
            switch repeatMode {
            case .one:
                nextIdx = currentIndex
            case .all:
                nextIdx = (currentIndex + 1) % queue.count
            case .off:
                let n = currentIndex + 1
                nextIdx = n < queue.count ? n : nil
            }
            if let idx = nextIdx, let nextSong = queue[safe: idx],
               nextSong.fileURL.isFileURL, FileManager.default.fileExists(atPath: nextSong.fileURL.path) {
                audioEngine.scheduleCrossfadeIfNeeded(nextURL: nextSong.fileURL, trackDuration: song.duration)
            }
        }

        updateNowPlayingInfo()
        MusicLibraryManager.shared.incrementPlayCount(for: song)
        savePlaybackState()
    }

    private func handleSongEnd() {
        switch repeatMode {
        case .one:
            load(song: queue[safe: currentIndex] ?? currentSong!)
        case .all:
            currentIndex = (currentIndex + 1) % queue.count
            load(song: queue[currentIndex])
        case .off:
            let next = currentIndex + 1
            if next < queue.count {
                currentIndex = next
                load(song: queue[next])
            } else {
                isPlaying = false
                currentTime = 0
            }
        }
        savePlaybackState()
    }

    private func shuffled(from songs: [Song], keeping song: Song?) -> [Song] {
        var result = songs.shuffled()
        if let song = song, let idx = result.firstIndex(where: { $0.id == song.id }) {
            result.remove(at: idx)
            result.insert(song, at: 0)
        }
        return result
    }

    // MARK: - Now Playing Info

    func updateNowPlayingInfo() {
        guard let song = currentSong else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: song.artist,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0
        ]
        if let data = song.artworkData, let image = UIImage(data: data) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // MARK: - Remote Commands

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in self?.play(); return .success }
        center.pauseCommand.addTarget { [weak self] _ in self?.pause(); return .success }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in self?.togglePlayPause(); return .success }
        center.nextTrackCommand.addTarget { [weak self] _ in self?.next(); return .success }
        center.previousTrackCommand.addTarget { [weak self] _ in self?.previous(); return .success }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let e = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seek(to: e.positionTime)
            return .success
        }
    }

    // MARK: - Notifications

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance())
        NotificationCenter.default.addObserver(self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance())
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        if type == .began {
            wasPlayingBeforeInterruption = isPlaying
            if isPlaying { pause() }
        } else if type == .ended {
            let opts = AVAudioSession.InterruptionOptions(
                rawValue: info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0)
            if opts.contains(.shouldResume) && wasPlayingBeforeInterruption {
                try? AVAudioSession.sharedInstance().setActive(true)
                play()
            }
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue),
              reason == .oldDeviceUnavailable else { return }
        DispatchQueue.main.async { self.pause() }
    }

    private func savePlaybackState() {
        let defaults = UserDefaults.standard
        defaults.set(queue.map { $0.id.uuidString }, forKey: queueIDsKey)
        defaults.set(currentIndex, forKey: currentIndexKey)
        defaults.set(currentSong?.id.uuidString, forKey: currentSongIDKey)
        defaults.set(shuffleEnabled, forKey: shuffleKey)
        defaults.set(repeatMode.rawValue, forKey: repeatModeKey)
    }

    private func restorePlaybackState() {
        let defaults = UserDefaults.standard
        shuffleEnabled = defaults.bool(forKey: shuffleKey)

        if let rawRepeat = defaults.string(forKey: repeatModeKey),
           let mode = RepeatMode(rawValue: rawRepeat) {
            repeatMode = mode
        }

        guard let idStrings = defaults.array(forKey: queueIDsKey) as? [String], !idStrings.isEmpty else { return }
        let ids = idStrings.compactMap(UUID.init(uuidString:))
        let allSongs = MusicLibraryManager.shared.songs
        let restoredQueue = ids.compactMap { id in
            allSongs.first { $0.id == id && $0.fileURL.isFileURL && FileManager.default.fileExists(atPath: $0.fileURL.path) }
        }
        guard !restoredQueue.isEmpty else { return }

        queue = restoredQueue
        originalQueue = restoredQueue
        currentIndex = min(max(defaults.integer(forKey: currentIndexKey), 0), max(0, restoredQueue.count - 1))

        if let currentIDString = defaults.string(forKey: currentSongIDKey),
           let currentID = UUID(uuidString: currentIDString),
           let song = restoredQueue.first(where: { $0.id == currentID }) {
            currentSong = song
            duration = song.duration
        } else if let song = restoredQueue[safe: currentIndex] {
            currentSong = song
            duration = song.duration
        }
    }
}

// MARK: - Safe subscript

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
