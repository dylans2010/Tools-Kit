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
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var playerItemObserver: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private var originalQueue: [Song] = []
    private var sleepTimerTimer: Timer?
    private var wasPlayingBeforeInterruption = false

    private init() {
        setupAudioSession()
        setupRemoteCommands()
        setupNotifications()
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

    // MARK: - Playback Control

    func play(song: Song, queue: [Song] = [], startIndex: Int = 0) {
        let sourceQueue = queue.isEmpty ? [song] : queue
        originalQueue = sourceQueue
        self.queue = shuffleEnabled ? shuffled(from: sourceQueue, keeping: song) : sourceQueue
        currentIndex = self.queue.firstIndex(where: { $0.id == song.id }) ?? 0
        load(song: song)
    }

    func play() {
        player?.play()
        isPlaying = true
        updateNowPlayingInfo()
    }

    func pause() {
        player?.pause()
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
            play()
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
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
        currentTime = time
        updateNowPlayingInfo()
    }

    // MARK: - Queue Management

    func addToQueue(_ song: Song) {
        queue.append(song)
        originalQueue.append(song)
    }

    func removeFromQueue(at offsets: IndexSet) {
        var adjusted = currentIndex
        for idx in offsets.sorted(by: >) {
            if idx < currentIndex { adjusted -= 1 }
        }
        queue.remove(atOffsets: offsets)
        originalQueue = queue
        currentIndex = adjusted
    }

    func moveInQueue(from source: IndexSet, to destination: Int) {
        queue.move(fromOffsets: source, toOffset: destination)
        originalQueue = queue
        if let song = currentSong, let newIdx = queue.firstIndex(where: { $0.id == song.id }) {
            currentIndex = newIdx
        }
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
    }

    func setRepeatMode(_ mode: RepeatMode) {
        repeatMode = mode
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

    // MARK: - Private helpers

    private func load(song: Song) {
        removeTimeObserver()
        currentSong = song
        duration = song.duration

        let item = AVPlayerItem(url: song.fileURL)
        if player == nil {
            player = AVPlayer(playerItem: item)
        } else {
            player?.replaceCurrentItem(with: item)
        }

        observePlayerItem(item)
        addTimeObserver()
        player?.play()
        isPlaying = true
        currentTime = 0
        updateNowPlayingInfo()
        MusicLibraryManager.shared.incrementPlayCount(for: song)
    }

    private func observePlayerItem(_ item: AVPlayerItem) {
        playerItemObserver = NotificationCenter.default
            .publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.handleSongEnd() }
    }

    private func handleSongEnd() {
        switch repeatMode {
        case .one:
            seek(to: 0)
            play()
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
    }

    private func addTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            let secs = CMTimeGetSeconds(time)
            if secs.isFinite { self.currentTime = secs }
            if let dur = self.player?.currentItem?.duration,
               dur.isValid, dur.timescale > 0 {
                let d = CMTimeGetSeconds(dur)
                if d.isFinite && d > 0 { self.duration = d }
            }
            self.updateNowPlayingInfo()
        }
    }

    private func removeTimeObserver() {
        if let obs = timeObserver {
            player?.removeTimeObserver(obs)
            timeObserver = nil
        }
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
}

// MARK: - Safe subscript

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
