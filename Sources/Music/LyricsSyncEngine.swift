import Foundation
import Combine

final class LyricsSyncEngine: ObservableObject {
    static let shared = LyricsSyncEngine()

    @Published var lines: [LyricLine] = []
    @Published var currentIndex: Int = -1
    @Published var isLoading: Bool = false
    @Published var offsetSeconds: TimeInterval = 0

    private let service = LyricsService()
    private var cancellables = Set<AnyCancellable>()
    private var currentSongID: UUID?

    private init() {
        MusicPlayerManager.shared.$currentSong
            .removeDuplicates { $0?.id == $1?.id }
            .sink { [weak self] song in
                self?.currentSongID = song?.id
                Task { await self?.loadLyrics(for: song) }
            }
            .store(in: &cancellables)

        MusicPlayerManager.shared.$currentTime
            .sink { [weak self] time in
                self?.sync(to: time)
            }
            .store(in: &cancellables)
    }

    // MARK: - Sync

    func sync(to currentTime: TimeInterval) {
        guard !lines.isEmpty else { return }
        let adjusted = currentTime + offsetSeconds
        var idx = -1
        for (i, line) in lines.enumerated() {
            if line.timestamp <= adjusted { idx = i } else { break }
        }
        if idx != currentIndex {
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.currentIndex = idx
                }
            }
        }
    }

    // MARK: - Load

    @MainActor
    func loadLyrics(for song: Song?) async {
        guard let song = song else {
            lines = []
            currentIndex = -1
            offsetSeconds = 0
            return
        }
        isLoading = true
        lines = []
        currentIndex = -1
        offsetSeconds = loadOffset(for: song)

        if let saved = service.loadSaved(for: song) {
            lines = saved
        } else if let fetched = await service.fetchSyncedLyrics(for: song) {
            lines = fetched
            service.save(fetched, for: song)
        }

        isLoading = false
    }

    // MARK: - Offset

    func saveOffset(_ offset: TimeInterval, for song: Song) {
        offsetSeconds = offset
        UserDefaults.standard.set(offset, forKey: "lyrics.offset.\(song.id.uuidString)")
    }

    private func loadOffset(for song: Song) -> TimeInterval {
        UserDefaults.standard.double(forKey: "lyrics.offset.\(song.id.uuidString)")
    }

    // MARK: - Manual lyric assignment

    func setLines(_ newLines: [LyricLine]) {
        lines = newLines.sorted { $0.timestamp < $1.timestamp }
    }
}
