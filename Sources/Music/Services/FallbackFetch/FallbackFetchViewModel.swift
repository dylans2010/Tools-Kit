import Foundation
import SwiftUI
import Combine

enum FetchStatus: Equatable {
    case idle
    case searching
    case ranking
    case fetchingAudio
    case downloading
    case completed
    case failed(String)
}

struct SongFetchItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let artist: String
    var status: FetchStatus = .idle
    var youtubeURL: String?
    var downloadURL: URL?
    var progress: Double = 0
}

final class FallbackFetchViewModel: ObservableObject {
    @Published var youtubeAPIKey: String = UserDefaults.standard.string(forKey: "youtubeDataAPIKey") ?? "" {
        didSet { UserDefaults.standard.set(youtubeAPIKey, forKey: "youtubeDataAPIKey") }
    }
    @Published var zylaAPIKey: String = UserDefaults.standard.string(forKey: "zylaLabsAPIKey") ?? "" {
        didSet { UserDefaults.standard.set(zylaAPIKey, forKey: "zylaLabsAPIKey") }
    }
    @Published var songs: [SongFetchItem] = []
    @Published var isProcessing: Bool = false
    @Published var overallProgress: Double = 0
    @Published var zipURL: URL?
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private let songsCheck = SongsCheck()
    private let songRank = SongRank()
    private let songGetAudio = SongGetAudio()
    private let songDownloadAudio = SongDownloadAudio()
    private let finishedFetch = FinishedFetch()
    private static let logFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    var canStartFetching: Bool {
        !songs.isEmpty && !youtubeAPIKey.isEmpty && !zylaAPIKey.isEmpty && !isProcessing
    }

    func importCSV(url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        do {
            let content = try String(contentsOf: url)
            parseCSV(content)
        } catch {
            errorMessage = "Failed to read CSV: \(error.localizedDescription)"
        }
    }

    private func parseCSV(_ content: String) {
        let lines = content.components(separatedBy: .newlines)
        guard lines.count > 1 else {
            errorMessage = "CSV file is empty or invalid"
            return
        }

        let headerFields = parseCSVLine(lines[0])
        let normalizedHeaders = headerFields.map { $0.trimmingCharacters(in: .init(charactersIn: "\" ")).lowercased() }

        guard let titleIndex = normalizedHeaders.firstIndex(where: { $0 == "track name" }),
              let artistIndex = normalizedHeaders.firstIndex(where: { $0 == "artist name(s)" }) else {
            errorMessage = "Could not find 'Track Name' and 'Artist Name(s)' columns in CSV"
            return
        }

        var importedSongs: [SongFetchItem] = []
        for i in 1..<lines.count {
            let line = lines[i]
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            let fields = parseCSVLine(line)
            if fields.count > max(titleIndex, artistIndex) {
                let title = fields[titleIndex].trimmingCharacters(in: .init(charactersIn: "\" "))
                let artist = fields[artistIndex].trimmingCharacters(in: .init(charactersIn: "\" "))
                if !title.isEmpty && !artist.isEmpty {
                    importedSongs.append(SongFetchItem(title: title, artist: artist))
                }
            }
        }

        self.songs = importedSongs
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        result.append(currentField)
        return result
    }

    func startFetchingFromUI() {
        Task {
            let snapshot = await MainActor.run { (songs.count, !youtubeAPIKey.isEmpty, !zylaAPIKey.isEmpty) }
            log("Start Fetching tapped (songs: \(snapshot.0), youtubeKey: \(snapshot.1), zylaKey: \(snapshot.2))")
            await startFetching()
        }
    }

    func startFetching() async {
        let state = await MainActor.run { (songs, youtubeAPIKey, zylaAPIKey) }
        let songsSnapshot = state.0
        let youtubeKey = state.1
        let zylaKey = state.2

        guard !youtubeKey.isEmpty else {
            await MainActor.run { errorMessage = "Please enter your YouTube Data API Key" }
            log("Blocked start: missing YouTube API key")
            return
        }

        guard !zylaKey.isEmpty else {
            await MainActor.run { errorMessage = "Please enter your Zyla Labs API Key" }
            log("Blocked start: missing Zyla API key")
            return
        }

        guard !songsSnapshot.isEmpty else {
            await MainActor.run { errorMessage = "No songs to fetch" }
            log("Blocked start: songs list is empty at execution time")
            return
        }

        await MainActor.run {
            isProcessing = true
            overallProgress = 0
            zipURL = nil
            errorMessage = nil
            for i in songs.indices {
                songs[i].status = .idle
                songs[i].youtubeURL = nil
                songs[i].downloadURL = nil
                songs[i].progress = 0
            }
        }

        log("Beginning fetch for \(songsSnapshot.count) songs")
        let totalSongs = Double(songsSnapshot.count)

        for (index, song) in songsSnapshot.enumerated() {
            log("Processing song \(index + 1)/\(songsSnapshot.count): \(song.title) - \(song.artist)")
            await processSong(song: song, index: index, youtubeAPIKey: youtubeKey, zylaAPIKey: zylaKey)
            await MainActor.run { overallProgress = Double(index + 1) / totalSongs }
        }

        do {
            let downloadedURLs = await MainActor.run { songs.compactMap { $0.downloadURL } }
            log("Download complete for \(downloadedURLs.count) songs, preparing ZIP")
            if !downloadedURLs.isEmpty {
                let zip = try await finishedFetch.createZip(from: downloadedURLs)
                await MainActor.run {
                    self.zipURL = zip
                    self.isProcessing = false
                }
                log("ZIP archive created at \(zip)")
            } else {
                await MainActor.run {
                    self.errorMessage = "No songs were successfully downloaded"
                    self.isProcessing = false
                }
                log("ZIP creation skipped: no downloaded URLs")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to create ZIP: \(error.localizedDescription)"
                self.isProcessing = false
            }
            log("ZIP creation failed: \(error.localizedDescription)")
        }
    }

    private func processSong(song: SongFetchItem, index: Int, youtubeAPIKey: String, zylaAPIKey: String) async {
        await updateStatus(index: index, status: .searching)
        let query = "\(song.title) \(song.artist)"

        do {
            let searchResults = try await songsCheck.search(query: query, youtubeAPIKey: youtubeAPIKey)
            guard !searchResults.isEmpty else {
                await updateStatus(index: index, status: .failed("No YouTube results found"))
                log("No YouTube results for \(song.title) - \(song.artist)")
                return
            }

            await updateStatus(index: index, status: .ranking)
            guard let bestMatch = songRank.findBestMatch(for: song, in: searchResults) else {
                await updateStatus(index: index, status: .failed("No suitable YouTube match found"))
                log("Ranking failed for \(song.title) - \(song.artist)")
                return
            }

            await updateYoutubeURL(index: index, url: bestMatch)
            log("Selected YouTube URL for \(song.title): \(bestMatch)")

            await updateStatus(index: index, status: .fetchingAudio)
            let audioURL = try await songGetAudio.getAudioLink(youtubeURL: bestMatch, zylaAPIKey: zylaAPIKey)
            log("Zyla returned audio URL for \(song.title)")

            await updateStatus(index: index, status: .downloading)
            let destinationURL = try await songDownloadAudio.download(
                from: audioURL,
                fileName: "\(song.title) - \(song.artist).mp3"
            )

            await updateDownloadURL(index: index, url: destinationURL)
            await updateStatus(index: index, status: .completed)
            log("Download completed for \(song.title), stored at \(destinationURL.lastPathComponent)")
        } catch {
            await updateStatus(index: index, status: .failed(error.localizedDescription))
            log("Song failed: \(song.title) - \(song.artist) error: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func updateStatus(index: Int, status: FetchStatus) {
        songs[index].status = status
    }

    @MainActor
    private func updateYoutubeURL(index: Int, url: String) {
        songs[index].youtubeURL = url
    }

    @MainActor
    private func updateDownloadURL(index: Int, url: URL) {
        songs[index].downloadURL = url
    }

    private func log(_ message: String) {
        let timestamp = Self.logFormatter.string(from: Date())
        print("[FallbackFetch] \(timestamp) \(message)")
    }
}
