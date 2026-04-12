import SwiftUI
import Combine

@MainActor
final class SpotifyFetchViewModel: ObservableObject {
    @Published var playlistURL: String = ""
    @Published var manualTrackInput: String = ""
    @Published var matchedTracks: [MatchedTrack] = []
    @Published var isImporting = false
    @Published var isDownloading = false
    @Published var isMatching = false
    @Published var isExporting = false
    @Published var showManualFallback = false
    @Published var errorMessage: String?
    @Published var exportURL: URL?
    @Published var hasDownloadedFiles = false

    @Published var progressMessage: String = ""
    @Published var overallProgress: Double = 0
    @Published var logs: [String] = []

    private let fetchService = SpotifyFetchService()
    private let matchingService = TrackMatchingService()
    private let downloadManager = DownloadManager()
    private let zipExportService = ZipExportService()

    private let maxConcurrentMatches = 6
    private var currentTask: Task<Void, Never>?

    private var cancellables = Set<AnyCancellable>()

    init() {
        self.loadSession()
        self.refreshDownloadState()
    }

    func importPlaylist() {
        cancelCurrentTask()
        currentTask = Task {
            isImporting = true
            errorMessage = nil
            showManualFallback = false
            matchedTracks = []
            progressMessage = "Connecting to Spotify..."
            overallProgress = 0
            log("Starting playlist import: \(playlistURL)")

            do {
                let stream = await fetchService.fetchPlaylistTracksStreaming(from: playlistURL)

                for try await chunk in stream {
                    if Task.isCancelled { break }

                    let newMatched = chunk.map { track in
                        MatchedTrack(
                            original: track,
                            matchedTitle: nil,
                            matchedArtist: nil,
                            sourceType: .none,
                            sourceURL: nil,
                            confidence: 0,
                            reason: .none,
                            status: .queued
                        )
                    }

                    self.matchedTracks.append(contentsOf: newMatched)
                    log("Ingested chunk of \(chunk.count) tracks. Total: \(matchedTracks.count)")

                    // Controlled matching: process this chunk before getting the next one if we want total control,
                    // or just await the matching of this chunk.
                    await matchTracks(chunk)
                }

                if matchedTracks.isEmpty && !Task.isCancelled {
                    showManualFallback = true
                    errorMessage = "No tracks found in playlist."
                }

                log("Import stream completed.")
            } catch {
                if !Task.isCancelled {
                    showManualFallback = true
                    errorMessage = error.localizedDescription
                    log("Import failed: \(error.localizedDescription)")
                }
            }

            isImporting = false
            saveSession()
        }
    }

    func importManualTracks() {
        cancelCurrentTask()
        currentTask = Task {
            let tracks = await fetchService.parseManualTrackList(manualTrackInput)
            guard !tracks.isEmpty else {
                errorMessage = "Add at least one track line in the format: Song - Artist"
                return
            }
            errorMessage = nil
            matchedTracks = tracks.map {
                MatchedTrack(
                    original: $0,
                    matchedTitle: nil,
                    matchedArtist: nil,
                    sourceType: .none,
                    sourceURL: nil,
                    confidence: 0,
                    reason: .none,
                    status: .queued
                )
            }
            log("Imported \(matchedTracks.count) manual tracks.")
            await matchTracks(tracks)
        }
    }

    func downloadAvailableTracks() {
        cancelCurrentTask()
        currentTask = Task {
            isDownloading = true
            progressMessage = "Downloading tracks..."
            overallProgress = 0
            log("Starting batch download.")

            let tracksToDownload = matchedTracks.filter { $0.sourceType == .local && $0.status == .matched }
            let total = tracksToDownload.count
            var completed = 0

            let _ = await downloadManager.downloadAvailableTracks(from: tracksToDownload) { [weak self] id, url in
                Task { @MainActor in
                    completed += 1
                    if let index = self?.matchedTracks.firstIndex(where: { $0.id == id }) {
                        if url != nil {
                            self?.matchedTracks[index].status = .downloaded
                            self?.matchedTracks[index].localFileURL = url
                        } else {
                            // Keep as matched if download failed
                            self?.log("Download failed for track ID: \(id)")
                        }
                    }
                    self?.overallProgress = Double(completed) / Double(max(1, total))
                    self?.progressMessage = "Downloaded \(completed) / \(total) tracks"
                }
            }

            hasDownloadedFiles = await downloadManager.hasDownloadedFiles()
            isDownloading = false
            log("Batch download completed.")
            saveSession()
        }
    }

    func exportAsZIP() {
        isExporting = true
        progressMessage = "Creating ZIP archive..."
        overallProgress = 0
        log("Starting ZIP export.")

        do {
            exportURL = try zipExportService.exportDownloadedFilesAsPlaylistZip { progress in
                DispatchQueue.main.async {
                    self.overallProgress = progress
                }
            }
            errorMessage = nil
            log("ZIP export successful.")
        } catch {
            errorMessage = error.localizedDescription
            log("ZIP export failed: \(error.localizedDescription)")
        }
        isExporting = false
    }

    func cancelCurrentTask() {
        currentTask?.cancel()
        currentTask = nil
        isImporting = false
        isMatching = false
        isDownloading = false
        isExporting = false
        progressMessage = "Cancelled"
        log("Current operation cancelled by user.")
    }

    func openSourceIfNeeded(for track: MatchedTrack) {
        guard track.sourceType == .external,
              let sourceURL = track.sourceURL,
              let url = URL(string: sourceURL) else {
            return
        }
        UIApplication.shared.open(url)
    }

    func refreshDownloadState() {
        Task {
            hasDownloadedFiles = await downloadManager.hasDownloadedFiles()
        }
    }

    // MARK: - Pipeline Logic

    private func matchTracks(_ tracks: [SpotifyTrack]) async {
        isMatching = true
        let librarySongs = MusicLibraryManager.shared.songs
        let total = tracks.count
        var matchedCount = 0

        for start in stride(from: 0, to: tracks.count, by: maxConcurrentMatches) {
            if Task.isCancelled { break }

            let end = min(start + maxConcurrentMatches, tracks.count)
            let chunk = Array(tracks[start..<end])

            await withTaskGroup(of: (String, MatchedTrack).self) { group in
                for track in chunk {
                    group.addTask { [matchingService] in
                        let matched = await matchingService.match(track: track, localSongs: librarySongs)
                        return (track.id, matched)
                    }
                }

                for await (id, matched) in group {
                    if let index = self.matchedTracks.firstIndex(where: { $0.id == id }) {
                        self.matchedTracks[index] = matched
                    }
                    matchedCount += 1
                    // Update overall progress based on the total matchedTracks count for better UX during streaming
                    let totalToMatch = matchedTracks.count
                    let currentMatched = matchedTracks.filter { $0.status != .queued }.count
                    self.overallProgress = Double(currentMatched) / Double(max(1, totalToMatch))
                    self.progressMessage = "Matching \(currentMatched) / \(totalToMatch) tracks"
                }
            }
        }

        isMatching = false
        saveSession()
    }

    // MARK: - Persistence

    private var sessionURL: URL {
        let musicDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Music", isDirectory: true)
        return musicDirectory.appendingPathComponent("spotify-fetch-session.json")
    }

    private func saveSession() {
        guard let data = try? JSONEncoder().encode(matchedTracks) else { return }
        try? data.write(to: sessionURL, options: .atomic)
    }

    private func loadSession() {
        guard let data = try? Data(contentsOf: sessionURL),
              let decoded = try? JSONDecoder().decode([MatchedTrack].self, from: data) else {
            return
        }
        self.matchedTracks = decoded
        log("Restored previous session with \(matchedTracks.count) tracks.")
    }

    // MARK: - Logging

    private func log(_ message: String) {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        let timestamp = formatter.string(from: Date())
        let fullMessage = "[\(timestamp)] \(message)"
        logs.append(fullMessage)
        if logs.count > 100 { logs.removeFirst() }
        print(fullMessage)
    }
}
