import Foundation
import SwiftUI
import ZIPFoundation

// MARK: - Logging

enum LogLevel: String {
    case debug = "DEBUG"
    case info  = "INFO"
    case warning = "WARN"
    case error = "ERROR"

    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "✅"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}

enum PipelineStage: String {
    case ui       = "UI"
    case parsing  = "PARSING"
    case youtube  = "YOUTUBE"
    case zyla     = "ZYLA"
    case polling  = "POLLING"
    case download = "DOWNLOAD"
    case zip      = "ZIP"
    case system   = "SYSTEM"
}

struct LogEntry: Identifiable {
    let id: UUID = UUID()
    let timestamp: Date
    let level: LogLevel
    let stage: PipelineStage
    let message: String
    let metadata: [String: String]?

    var formattedTimestamp: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f.string(from: timestamp)
    }
}

@MainActor
final class LogManager: ObservableObject {
    static let shared = LogManager()
    private init() {}

    @Published private(set) var entries: [LogEntry] = []
    var debugMode: Bool = true

    func log(
        level: LogLevel,
        stage: PipelineStage,
        message: String,
        metadata: [String: String]? = nil
    ) {
        guard level != .debug || debugMode else { return }

        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            stage: stage,
            message: message,
            metadata: metadata
        )

        entries.append(entry)
    }

    func clear() {
        entries.removeAll()
    }
}

// MARK: - Errors

enum FetchError: LocalizedError {
    case urlEncoding(query: String)
    case invalidURL(String)
    case invalidResponse
    case httpError(code: Int)
    case noYouTubeResults(title: String)
    case zylaError(String)
    case missingJobId(String)
    case missingDownloadURL(String)
    case jobFailed(String)
    case pollingTimeout(jobId: String)
    case downloadFailed(String)
    case zipCreationFailed

    var errorDescription: String? {
        switch self {
        case .urlEncoding(let q): return "URL encoding failed for query: \(q)"
        case .invalidURL(let u): return "Invalid URL: \(u)"
        case .invalidResponse: return "Response was not HTTPURLResponse"
        case .httpError(let c): return "HTTP error: \(c)"
        case .noYouTubeResults(let t): return "No YouTube results for: \(t)"
        case .zylaError(let b): return "Zyla API error: \(b)"
        case .missingJobId(let b): return "Missing job_id in: \(b)"
        case .missingDownloadURL(let b): return "Missing download URL in: \(b)"
        case .jobFailed(let id): return "Job explicitly failed: \(id)"
        case .pollingTimeout(let id): return "Polling timed out for: \(id)"
        case .downloadFailed(let name): return "Download failed for: \(name)"
        case .zipCreationFailed: return "Failed to create ZIP archive"
        }
    }
}

// MARK: - Models

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

    var safeFileName: String {
        "\(title) - \(artist)".replacingOccurrences(of: "/", with: "-")
    }
}

struct SongResult {
    enum Status {
        case success
        case failed
    }

    let song: SongFetchItem
    let status: Status
    let fileURL: URL?
    let error: Error?
}

// MARK: - ViewModel

final class FallbackFetchViewModel: ObservableObject {
    @Published var youtubeAPIKey: String = UserDefaults.standard.string(forKey: "youtubeDataAPIKey") ?? "" {
        didSet { UserDefaults.standard.set(youtubeAPIKey, forKey: "youtubeDataAPIKey") }
    }
    @Published var zylaAPIKey: String = UserDefaults.standard.string(forKey: "zylaLabsAPIKey") ?? "" {
        didSet { UserDefaults.standard.set(zylaAPIKey, forKey: "zylaLabsAPIKey") }
    }
    @Published var songs: [SongFetchItem] = []
    @Published var isFetching: Bool = false
    @Published var overallProgress: Double = 0
    @Published var zipURL: URL?
    @Published var errorMessage: String?
    @Published var results: [SongResult] = []

    private var downloadedFiles: [URL] = []
    private var activeYouTubeAPIKey: String = ""
    private var activeZylaAPIKey: String = ""

    var canStartFetching: Bool {
        !songs.isEmpty && !youtubeAPIKey.isEmpty && !zylaAPIKey.isEmpty && !isFetching
    }

    init() {
        LogManager.shared.debugMode = true
    }

    func importCSV(url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        do {
            let content = try String(contentsOf: url)
            parseCSV(content)
        } catch {
            errorMessage = "Failed to read CSV: \(error.localizedDescription)"
            Task {
                await LogManager.shared.log(
                    level: .error,
                    stage: .parsing,
                    message: "Failed to read CSV",
                    metadata: ["error": error.localizedDescription]
                )
            }
        }
    }

    private func parseCSV(_ content: String) {
        let lines = content.components(separatedBy: .newlines)
        guard lines.count > 1 else {
            errorMessage = "CSV file is empty or invalid"
            Task {
                await LogManager.shared.log(
                    level: .error,
                    stage: .parsing,
                    message: "CSV file is empty or invalid",
                    metadata: nil
                )
            }
            return
        }

        let headerFields = parseCSVLine(lines[0])
        let normalizedHeaders = headerFields.map { $0.trimmingCharacters(in: .init(charactersIn: "\" ")).lowercased() }

        guard let titleIndex = normalizedHeaders.firstIndex(where: { $0 == "track name" }),
              let artistIndex = normalizedHeaders.firstIndex(where: { $0 == "artist name(s)" }) else {
            errorMessage = "Could not find 'Track Name' and 'Artist Name(s)' columns in CSV"
            Task {
                await LogManager.shared.log(
                    level: .error,
                    stage: .parsing,
                    message: "CSV header missing required columns",
                    metadata: ["headers": "\(normalizedHeaders)"]
                )
            }
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

        Task {
            await LogManager.shared.log(
                level: .info,
                stage: .parsing,
                message: "CSV parsed",
                metadata: ["count": "\(importedSongs.count)"]
            )
            await MainActor.run {
                self.songs = importedSongs
            }
        }
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
            await LogManager.shared.log(
                level: .info,
                stage: .ui,
                message: "Start Fetching tapped from UI",
                metadata: nil
            )
            await startFetching()
        }
    }

    func startFetching() async {
        await LogManager.shared.clear()
        await LogManager.shared.log(
            level: .info,
            stage: .ui,
            message: "Start Fetching triggered",
            metadata: nil
        )

        let snapshot = await MainActor.run { (songs, youtubeAPIKey, zylaAPIKey) }
        let songsSnapshot = snapshot.0
        activeYouTubeAPIKey = snapshot.1
        activeZylaAPIKey = snapshot.2

        await LogManager.shared.log(
            level: .info,
            stage: .ui,
            message: "Songs loaded: \(songsSnapshot.count) total",
            metadata: ["count": "\(songsSnapshot.count)"]
        )

        let preview = songsSnapshot.prefix(3).map { $0.title }.joined(separator: ", ")
        await LogManager.shared.log(
            level: .debug,
            stage: .ui,
            message: "First songs: \(preview)",
            metadata: nil
        )

        await MainActor.run {
            isFetching = true
            overallProgress = 0
            zipURL = nil
            errorMessage = nil
        }

        defer {
            Task { await MainActor.run { self.isFetching = false } }
        }

        guard !songsSnapshot.isEmpty else {
            await LogManager.shared.log(
                level: .error,
                stage: .ui,
                message: "ABORT: songs array is empty at runtime",
                metadata: nil
            )
            await MainActor.run { self.errorMessage = "No songs to fetch" }
            return
        }

        guard !activeYouTubeAPIKey.isEmpty else {
            await LogManager.shared.log(
                level: .error,
                stage: .ui,
                message: "ABORT: missing YouTube Data API key",
                metadata: nil
            )
            await MainActor.run { self.errorMessage = "Please enter your YouTube Data API Key" }
            return
        }

        guard !activeZylaAPIKey.isEmpty else {
            await LogManager.shared.log(
                level: .error,
                stage: .ui,
                message: "ABORT: missing Zyla Labs API key",
                metadata: nil
            )
            await MainActor.run { self.errorMessage = "Please enter your Zyla Labs API Key" }
            return
        }

        await resetState()
        await processSongsSequentially()
    }

    // MARK: - Pipeline

    private func processSongsSequentially() async {
        let currentSongs = await MainActor.run { songs }
        await MainActor.run { downloadedFiles.removeAll() }
        await MainActor.run { results.removeAll() }

        for (index, song) in currentSongs.enumerated() {
            await LogManager.shared.log(
                level: .info,
                stage: .system,
                message: "[\(index + 1)/\(currentSongs.count)] Processing: \(song.title) — \(song.artist)",
                metadata: nil
            )
            await updateStatus(for: song.id, status: .searching)

            do {
                let result = try await processSong(song)
                await LogManager.shared.log(
                    level: .info,
                    stage: .system,
                    message: "[\(index + 1)/\(currentSongs.count)] SUCCESS: \(song.title)",
                    metadata: nil
                )
                await MainActor.run {
                    results.append(result)
                    if let file = result.fileURL {
                        downloadedFiles.append(file)
                        if let idx = songs.firstIndex(where: { $0.id == song.id }) {
                            songs[idx].downloadURL = file
                            songs[idx].progress = 1
                            songs[idx].status = .completed
                        }
                    }
                }
            } catch {
                await LogManager.shared.log(
                    level: .error,
                    stage: .system,
                    message: "[\(index + 1)/\(currentSongs.count)] FAILED: \(song.title) — \(error.localizedDescription)",
                    metadata: ["error": "\(error)"]
                )
                await MainActor.run {
                    results.append(SongResult(song: song, status: .failed, fileURL: nil, error: error))
                    if let idx = songs.firstIndex(where: { $0.id == song.id }) {
                        songs[idx].status = .failed(error.localizedDescription)
                    }
                }
            }

            await MainActor.run {
                overallProgress = Double(index + 1) / Double(currentSongs.count)
            }
        }

        await finalizePipeline()
    }

    func processSong(_ song: SongFetchItem) async throws -> SongResult {
        let videoId = try await searchYouTube(song)
        await updateStatus(for: song.id, status: .ranking)

        let youTubeURL = "https://www.youtube.com/watch?v=\(videoId)"
        await updateYoutubeURL(for: song.id, url: youTubeURL)

        await updateStatus(for: song.id, status: .fetchingAudio)
        let jobId = try await convertToMP3(videoId: videoId)

        let downloadURLString = try await pollJobStatus(jobId: jobId)

        await updateStatus(for: song.id, status: .downloading)
        let fileURL = try await downloadMP3(from: downloadURLString, for: song)

        return SongResult(song: song, status: .success, fileURL: fileURL, error: nil)
    }

    private func finalizePipeline() async {
        let files = await MainActor.run { downloadedFiles }

        guard !files.isEmpty else {
            await LogManager.shared.log(
                level: .warning,
                stage: .zip,
                message: "ZIP creation skipped: no downloaded files",
                metadata: nil
            )
            await MainActor.run {
                errorMessage = "No songs were successfully downloaded"
            }
            return
        }

        do {
            let zip = try await createZIPArchive(from: files)
            await MainActor.run {
                zipURL = zip
            }
        } catch {
            await LogManager.shared.log(
                level: .error,
                stage: .zip,
                message: "ZIP creation failed: \(error.localizedDescription)",
                metadata: ["error": "\(error)"]
            )
            await MainActor.run {
                errorMessage = "Failed to create ZIP: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - YouTube

    private func buildYouTubeURL(_ song: SongFetchItem) throws -> URL {
        let query = "\(song.title) \(song.artist)"

        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw FetchError.urlEncoding(query: query)
        }

        let urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(encoded)&type=video&maxResults=1&key=\(activeYouTubeAPIKey)"

        guard let url = URL(string: urlString) else {
            throw FetchError.invalidURL(urlString)
        }

        return url
    }

    private func searchYouTube(_ song: SongFetchItem) async throws -> String {
        await LogManager.shared.log(
            level: .info,
            stage: .youtube,
            message: "Searching YouTube for: \(song.title) — \(song.artist)",
            metadata: nil
        )

        let url = try buildYouTubeURL(song)
        await LogManager.shared.log(
            level: .debug,
            stage: .youtube,
            message: "YouTube request prepared",
            metadata: ["url": url.absoluteString]
        )
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw FetchError.invalidResponse
        }

        await LogManager.shared.log(
            level: .info,
            stage: .youtube,
            message: "YouTube HTTP status: \(http.statusCode)",
            metadata: ["song": song.title, "status": "\(http.statusCode)"]
        )

        guard http.statusCode == 200 else {
            let raw = String(data: data, encoding: .utf8) ?? "unreadable"
            await LogManager.shared.log(
                level: .error,
                stage: .youtube,
                message: "YouTube non-200 response",
                metadata: ["status": "\(http.statusCode)", "body_snippet": String(raw.prefix(300))]
            )
            throw FetchError.httpError(code: http.statusCode)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let items = json?["items"] as? [[String: Any]]

        if let videoId = (items?.first?["id"] as? [String: Any])?["videoId"] as? String {
            await LogManager.shared.log(
                level: .info,
                stage: .youtube,
                message: "videoId found: \(videoId)",
                metadata: ["song": song.title, "videoId": videoId]
            )
            return videoId
        }

        await LogManager.shared.log(
            level: .warning,
            stage: .youtube,
            message: "No results for full query, retrying with title only",
            metadata: ["song": song.title]
        )

        return try await searchYouTubeFallback(title: song.title)
    }

    private func searchYouTubeFallback(title: String) async throws -> String {
        let query = title
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw FetchError.urlEncoding(query: query)
        }

        let urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(encoded)&type=video&maxResults=1&key=\(activeYouTubeAPIKey)"
        guard let url = URL(string: urlString) else { throw FetchError.invalidURL(urlString) }

        await LogManager.shared.log(
            level: .debug,
            stage: .youtube,
            message: "Fallback YouTube search",
            metadata: ["url": urlString]
        )

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw FetchError.httpError(code: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let items = json?["items"] as? [[String: Any]]

        if let videoId = (items?.first?["id"] as? [String: Any])?["videoId"] as? String {
            await LogManager.shared.log(
                level: .info,
                stage: .youtube,
                message: "Fallback videoId found: \(videoId)",
                metadata: ["title": title]
            )
            return videoId
        }

        await LogManager.shared.log(
            level: .error,
            stage: .youtube,
            message: "No YouTube results after fallback",
            metadata: ["title": title]
        )
        throw FetchError.noYouTubeResults(title: title)
    }

    // MARK: - Zyla

    private func convertToMP3(videoId: String) async throws -> String {
        let fullURL = "https://www.youtube.com/watch?v=\(videoId)"

        await LogManager.shared.log(
            level: .info,
            stage: .zyla,
            message: "Sending to Zyla: \(fullURL)",
            metadata: ["videoId": videoId, "fullURL": fullURL]
        )

        guard let endpointURL = URL(string: ZylaConfig.convertEndpoint) else {
            throw FetchError.invalidURL(ZylaConfig.convertEndpoint)
        }

        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(activeZylaAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["url": fullURL, "link": fullURL]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        await LogManager.shared.log(
            level: .debug,
            stage: .zyla,
            message: "Zyla request headers set",
            metadata: ["body": "\(body)"]
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let http = response as? HTTPURLResponse

        let rawBody = String(data: data, encoding: .utf8) ?? "unreadable"

        await LogManager.shared.log(
            level: .info,
            stage: .zyla,
            message: "Zyla response: HTTP \(http?.statusCode ?? -1)",
            metadata: ["status": "\(http?.statusCode ?? -1)", "body_snippet": String(rawBody.prefix(500))]
        )

        guard let status = http?.statusCode, status == 200 || status == 202 else {
            await LogManager.shared.log(
                level: .error,
                stage: .zyla,
                message: "Zyla non-success response",
                metadata: ["body": rawBody]
            )
            throw FetchError.zylaError(rawBody)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        if let link = json?["link"] as? String, !link.isEmpty {
            await LogManager.shared.log(
                level: .info,
                stage: .zyla,
                message: "Direct download link returned",
                metadata: ["url": link]
            )
            return link
        }

        guard let jobId = json?["job_id"] as? String ?? json?["jobId"] as? String ?? json?["id"] as? String else {
            await LogManager.shared.log(
                level: .error,
                stage: .zyla,
                message: "No job_id in Zyla response",
                metadata: ["full_body": rawBody]
            )
            throw FetchError.missingJobId(rawBody)
        }

        await LogManager.shared.log(
            level: .info,
            stage: .zyla,
            message: "job_id received: \(jobId)",
            metadata: ["jobId": jobId]
        )

        return jobId
    }

    private func pollJobStatus(jobId: String) async throws -> String {
        // If the Zyla API returned a direct URL, bypass polling entirely.
        if jobId.lowercased().hasPrefix("http") {
            await LogManager.shared.log(
                level: .info,
                stage: .polling,
                message: "Polling bypassed, direct URL supplied",
                metadata: ["url": jobId]
            )
            return jobId
        }

        let maxAttempts = 30
        let delaySeconds: UInt64 = 3_000_000_000

        await LogManager.shared.log(
            level: .info,
            stage: .polling,
            message: "Polling started for job: \(jobId)",
            metadata: ["jobId": jobId, "maxAttempts": "\(maxAttempts)"]
        )

        for attempt in 1...maxAttempts {
            try await Task.sleep(nanoseconds: delaySeconds)

            await LogManager.shared.log(
                level: .debug,
                stage: .polling,
                message: "Poll attempt \(attempt)/\(maxAttempts)",
                metadata: ["jobId": jobId, "attempt": "\(attempt)"]
            )

            guard let url = URL(string: "\(ZylaConfig.statusEndpoint)/\(jobId)") else {
                throw FetchError.invalidURL(ZylaConfig.statusEndpoint)
            }

            var request = URLRequest(url: url)
            request.setValue("Bearer \(activeZylaAPIKey)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)
            let rawBody = String(data: data, encoding: .utf8) ?? "unreadable"
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let status = json?["status"] as? String ?? "unknown"

            await LogManager.shared.log(
                level: .info,
                stage: .polling,
                message: "Poll \(attempt) status: \(status)",
                metadata: ["jobId": jobId, "status": status]
            )

            switch status.lowercased() {
            case "completed", "done", "success", "finished":
                if let downloadURL = json?["download_url"] as? String
                    ?? json?["url"] as? String
                    ?? json?["mp3_url"] as? String
                    ?? json?["link"] as? String {
                    await LogManager.shared.log(
                        level: .info,
                        stage: .polling,
                        message: "Download URL obtained: \(downloadURL)",
                        metadata: ["jobId": jobId, "url": downloadURL]
                    )
                    return downloadURL
                } else {
                    await LogManager.shared.log(
                        level: .error,
                        stage: .polling,
                        message: "Status completed but no download URL found",
                        metadata: ["body": rawBody]
                    )
                    throw FetchError.missingDownloadURL(rawBody)
                }
            case "failed", "error":
                await LogManager.shared.log(
                    level: .error,
                    stage: .polling,
                    message: "Job explicitly failed at attempt \(attempt)",
                    metadata: ["jobId": jobId, "body": rawBody]
                )
                throw FetchError.jobFailed(jobId)
            default:
                continue
            }
        }

        await LogManager.shared.log(
            level: .error,
            stage: .polling,
            message: "Polling timed out after \(maxAttempts) attempts",
            metadata: ["jobId": jobId]
        )
        throw FetchError.pollingTimeout(jobId: jobId)
    }

    // MARK: - Download

    private func downloadMP3(from urlString: String, for song: SongFetchItem) async throws -> URL {
        guard let url = URL(string: urlString) else {
            await LogManager.shared.log(
                level: .error,
                stage: .download,
                message: "Invalid download URL: \(urlString)",
                metadata: ["song": song.title]
            )
            throw FetchError.invalidURL(urlString)
        }

        await LogManager.shared.log(
            level: .info,
            stage: .download,
            message: "Downloading MP3 for: \(song.title)",
            metadata: ["url": urlString]
        )

        let (tempURL, response) = try await URLSession.shared.download(from: url)
        let http = response as? HTTPURLResponse

        await LogManager.shared.log(
            level: .info,
            stage: .download,
            message: "Download response: HTTP \(http?.statusCode ?? -1)",
            metadata: ["song": song.title]
        )

        guard http?.statusCode == 200 else {
            throw FetchError.downloadFailed(song.title)
        }

        let destinationDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FallbackFetch", isDirectory: true)

        try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)

        let destination = destinationDir.appendingPathComponent("\(song.safeFileName).mp3")

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }

        try FileManager.default.moveItem(at: tempURL, to: destination)

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: destination.path)[.size] as? Int) ?? 0

        await LogManager.shared.log(
            level: .info,
            stage: .download,
            message: "File saved: \(destination.lastPathComponent) (\(fileSize) bytes)",
            metadata: ["song": song.title, "path": destination.path, "bytes": "\(fileSize)"]
        )

        if fileSize <= 1_000 {
            await LogManager.shared.log(
                level: .warning,
                stage: .download,
                message: "File suspiciously small — may be corrupt",
                metadata: ["song": song.title, "bytes": "\(fileSize)"]
            )
        }

        return destination
    }

    // MARK: - ZIP

    private func createZIPArchive(from files: [URL]) async throws -> URL {
        await LogManager.shared.log(
            level: .info,
            stage: .zip,
            message: "Starting ZIP creation for \(files.count) files",
            metadata: nil
        )

        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let zipURL = documentsDir.appendingPathComponent("Songs.zip")

        if FileManager.default.fileExists(atPath: zipURL.path) {
            try FileManager.default.removeItem(at: zipURL)
        }

        guard let archive = Archive(url: zipURL, accessMode: .create) else {
            throw FetchError.zipCreationFailed
        }

        for fileURL in files {
            await LogManager.shared.log(
                level: .debug,
                stage: .zip,
                message: "Adding to ZIP: \(fileURL.lastPathComponent)",
                metadata: nil
            )
            try archive.addEntry(
                with: fileURL.lastPathComponent,
                relativeTo: fileURL.deletingLastPathComponent()
            )
        }

        let zipSize = (try? FileManager.default.attributesOfItem(atPath: zipURL.path)[.size] as? Int) ?? 0

        await LogManager.shared.log(
            level: .info,
            stage: .zip,
            message: "ZIP created successfully: \(zipSize) bytes",
            metadata: ["path": zipURL.path, "fileCount": "\(files.count)", "bytes": "\(zipSize)"]
        )

        return zipURL
    }

    // MARK: - Helpers

    @MainActor
    private func resetState() {
        zipURL = nil
        errorMessage = nil
        results = []
        downloadedFiles = []
        overallProgress = 0
        for i in songs.indices {
            songs[i].status = .idle
            songs[i].youtubeURL = nil
            songs[i].downloadURL = nil
            songs[i].progress = 0
        }
    }

    @MainActor
    private func updateStatus(for songID: UUID, status: FetchStatus) {
        if let idx = songs.firstIndex(where: { $0.id == songID }) {
            songs[idx].status = status
        }
    }

    @MainActor
    private func updateYoutubeURL(for songID: UUID, url: String) {
        if let idx = songs.firstIndex(where: { $0.id == songID }) {
            songs[idx].youtubeURL = url
        }
    }
}

// MARK: - Config

private enum ZylaConfig {
    static let convertEndpoint = "https://zylalabs.com/api/381/youtube+to+audio+api/351/get+audio"
    static let statusEndpoint  = "https://zylalabs.com/api/381/youtube+to+audio+api/351/status"
}
