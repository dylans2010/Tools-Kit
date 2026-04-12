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
    @Published var apiKey: String = ""
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

    func importCSV(url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

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

        let header = lines[0].lowercased()
        let columns = header.components(separatedBy: ",")

        guard let titleIndex = columns.firstIndex(where: { $0.contains("track") || $0.contains("title") || $0.contains("name") }),
              let artistIndex = columns.firstIndex(where: { $0.contains("artist") }) else {
            errorMessage = "Could not find 'Track Name' and 'Artist' columns in CSV"
            return
        }

        var importedSongs: [SongFetchItem] = []
        for i in 1..<lines.count {
            let line = lines[i]
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
        guard !apiKey.isEmpty else {
            errorMessage = "Please enter your Zyla Labs API Key"
            return
        }

        guard !songs.isEmpty else {
            errorMessage = "No songs to fetch"
            return
        }

        isProcessing = true
        overallProgress = 0
        zipURL = nil

        let totalSongs = Double(songs.count)

        for i in 0..<songs.count {
            await fetchSong(index: i)
            overallProgress = Double(i + 1) / totalSongs
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

        // 1. Search YouTube
        await updateStatus(index: index, status: .searching)
        let searchResults = await songsCheck.search(query: "\(song.title) \(song.artist)", apiKey: apiKey)

        guard !searchResults.isEmpty else {
            await updateStatus(index: index, status: .failed("No YouTube results found"))
            return
        }

        // 2. Rank Results
        await updateStatus(index: index, status: .ranking)
        if let bestMatch = songRank.findBestMatch(for: song, in: searchResults) {
            await updateYoutubeURL(index: index, url: bestMatch)

            // 3. Get Audio Link
            await updateStatus(index: index, status: .fetchingAudio)
            do {
                if let audioLink = try await songGetAudio.getAudioLink(youtubeURL: bestMatch, apiKey: apiKey) {

                    // 4. Download Audio
                    await updateStatus(index: index, status: .downloading)
                    let downloadedURL = try await songDownloadAudio.download(from: audioLink, fileName: "\(song.title) - \(song.artist).mp3")

                    await updateDownloadURL(index: index, url: downloadedURL)
                    await updateStatus(index: index, status: .completed)
                } else {
                    await updateStatus(index: index, status: .failed("Could not get audio link"))
                }
            } catch {
                await updateStatus(index: index, status: .failed(error.localizedDescription))
            }
        } else {
            await updateStatus(index: index, status: .failed("No suitable match found"))
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
