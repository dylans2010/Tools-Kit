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

    func startFetching() async {
        guard !youtubeAPIKey.isEmpty else {
            errorMessage = "Please enter your YouTube Data API Key"
            return
        }

        guard !zylaAPIKey.isEmpty else {
            errorMessage = "Please enter your Zyla Labs API Key"
            return
        }

        guard !songs.isEmpty else {
            errorMessage = "No songs to fetch"
            return
        }

        await MainActor.run {
            isProcessing = true
            overallProgress = 0
            zipURL = nil
            // Reset statuses
            for i in songs.indices { songs[i].status = .idle }
        }

        let totalSongs = Double(songs.count)

        for i in 0..<songs.count {
            await fetchSong(index: i)
            await MainActor.run {
                overallProgress = Double(i + 1) / totalSongs
            }
        }

        do {
            let downloadedURLs = songs.compactMap { $0.downloadURL }
            if !downloadedURLs.isEmpty {
                let zip = try await finishedFetch.createZip(from: downloadedURLs)
                await MainActor.run {
                    self.zipURL = zip
                    self.isProcessing = false
                }
            } else {
                await MainActor.run {
                    self.errorMessage = "No songs were successfully downloaded"
                    self.isProcessing = false
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to create ZIP: \(error.localizedDescription)"
                self.isProcessing = false
            }
        }
    }

    private func fetchSong(index: Int) async {
        let song = songs[index]

        // 1. Search YouTube using YouTube Data API v3
        await updateStatus(index: index, status: .searching)
        let query = "\(song.title) \(song.artist)"
        let searchResults = await songsCheck.search(query: query, youtubeAPIKey: youtubeAPIKey)

        guard !searchResults.isEmpty else {
            await updateStatus(index: index, status: .failed("No YouTube results found"))
            return
        }

        // 2. Rank results and pick the best match
        await updateStatus(index: index, status: .ranking)
        guard let bestMatch = songRank.findBestMatch(for: song, in: searchResults) else {
            await updateStatus(index: index, status: .failed("No suitable YouTube match found"))
            return
        }
        await updateYoutubeURL(index: index, url: bestMatch)

        // 3. Extract MP3 download URL via Zyla YouTube-to-Audio API
        await updateStatus(index: index, status: .fetchingAudio)
        do {
            let audioURL = try await songGetAudio.getAudioLink(youtubeURL: bestMatch, zylaAPIKey: zylaAPIKey)
            guard let audioURL = audioURL else {
                await updateStatus(index: index, status: .failed("Zyla returned no audio link"))
                return
            }

            // 4. Download the MP3 file
            await updateStatus(index: index, status: .downloading)
            let destinationURL = try await songDownloadAudio.download(
                from: audioURL,
                fileName: "\(song.title) - \(song.artist).mp3"
            )

            await updateDownloadURL(index: index, url: destinationURL)
            await updateStatus(index: index, status: .completed)
        } catch {
            await updateStatus(index: index, status: .failed(error.localizedDescription))
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
}
