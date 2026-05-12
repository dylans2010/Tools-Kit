import Foundation

// MARK: - Unsplash API Response Models

struct UnsplashSearchResponse: Codable, Sendable {
    let total: Int
    let totalPages: Int
    let results: [UnsplashPhoto]

    enum CodingKeys: String, CodingKey, Sendable {
        case total
        case totalPages = "total_pages"
        case results
    }
}

struct UnsplashPhoto: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let width: Int
    let height: Int
    let description: String?
    let altDescription: String?
    let urls: UnsplashPhotoURLs
    let user: UnsplashUser
    let links: UnsplashPhotoLinks

    enum CodingKeys: String, CodingKey, Sendable {
        case id, width, height, description
        case altDescription = "alt_description"
        case urls, user, links
    }

    static func == (lhs: UnsplashPhoto, rhs: UnsplashPhoto) -> Bool {
        lhs.id == rhs.id
    }
}

struct UnsplashPhotoURLs: Codable, Sendable {
    let raw: String
    let full: String
    let regular: String
    let small: String
    let thumb: String
}

struct UnsplashUser: Codable, Sendable {
    let id: String
    let name: String
    let username: String
}

struct UnsplashPhotoLinks: Codable, Sendable {
    let html: String
    let download: String
    let downloadLocation: String

    enum CodingKeys: String, CodingKey, Sendable {
        case html, download
        case downloadLocation = "download_location"
    }
}

// MARK: - Unsplash Provider Error

enum UnsplashProviderError: LocalizedError, Equatable, Sendable {
    case missingAPIKey
    case invalidAPIKey
    case networkError(String)
    case decodingError(String)
    case noResults
    case rateLimited
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Unsplash API key is not configured. Add your key in App Settings → API Keys."
        case .invalidAPIKey:
            return "The Unsplash API key is invalid or has been revoked."
        case .networkError(let detail):
            return "Network error: \(detail)"
        case .decodingError(let detail):
            return "Failed to decode Unsplash response: \(detail)"
        case .noResults:
            return "No images found for this search query."
        case .rateLimited:
            return "Unsplash API rate limit exceeded. Try again later."
        case .serverError(let code):
            return "Unsplash server error (HTTP \(code))."
        }
    }
}

// MARK: - UnsplashProvider

final class UnsplashProvider: AISlidesImageProvider {
    static let shared = UnsplashProvider()
    static let providerID = "unsplash"

    private let baseURL = "https://api.unsplash.com"
    private let session: URLSession
    private let keyManager = APIKeyManager.shared

    private let memoryCache = UnsplashMemoryCache()
    private let diskCache = UnsplashDiskCache()
    private let inflightTracker = UnsplashInflightTracker()

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - AISlidesImageProvider conformance

    func imageURL(for query: String) async -> URL? {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let result: Result<UnsplashSearchResponse, UnsplashProviderError>

        if trimmedQuery.isEmpty {
            result = await randomPhotos(count: 1)
        } else {
            result = await search(query: trimmedQuery, page: 1, perPage: 1)
        }
        switch result {
        case .success(let response):
            guard let photo = response.results.first else { return nil }
            return URL(string: photo.urls.regular)
        case .failure:
            return nil
        }
    }


    func randomPhotos(count: Int = 30) async -> Result<UnsplashSearchResponse, UnsplashProviderError> {
        let safeCount = max(1, min(50, count))

        guard let accessKey = resolveAccessKey() else {
            return .failure(.missingAPIKey)
        }

        guard var components = URLComponents(string: "\(baseURL)/photos/random") else {
            return .failure(.networkError("Invalid base URL."))
        }

        components.queryItems = [
            URLQueryItem(name: "count", value: "\(safeCount)")
        ]

        guard let requestURL = components.url else {
            return .failure(.networkError("Failed to construct request URL."))
        }

        var request = buildRequest(url: requestURL, accessKey: accessKey)
        request.timeoutInterval = 15

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.networkError("Invalid response type."))
            }

            if let error = mapHTTPError(httpResponse.statusCode) {
                return .failure(error)
            }

            let decoder = JSONDecoder()
            let photos = try decoder.decode([UnsplashPhoto].self, from: data)

            if photos.isEmpty {
                return .failure(.noResults)
            }

            return .success(UnsplashSearchResponse(total: photos.count, totalPages: 1, results: photos))
        } catch is DecodingError {
            return .failure(.decodingError("Response did not match expected Unsplash schema."))
        } catch let urlError as URLError {
            return .failure(.networkError(urlError.localizedDescription))
        } catch {
            return .failure(.networkError(error.localizedDescription))
        }
    }

    // MARK: - Full Search API

    func search(
        query: String,
        page: Int = 1,
        perPage: Int = 30,
        orientation: String? = nil
    ) async -> Result<UnsplashSearchResponse, UnsplashProviderError> {
        let cacheKey = UnsplashCacheKey(query: query, page: page)

        if let cached = await memoryCache.get(for: cacheKey) {
            if !cached.isStale {
                return .success(cached.response)
            }
            Task { await refreshInBackground(query: query, page: page, perPage: perPage, orientation: orientation, cacheKey: cacheKey) }
            return .success(cached.response)
        }

        if let diskCached = await diskCache.get(for: cacheKey) {
            await memoryCache.set(diskCached, for: cacheKey)
            if !diskCached.isStale {
                return .success(diskCached.response)
            }
            Task { await refreshInBackground(query: query, page: page, perPage: perPage, orientation: orientation, cacheKey: cacheKey) }
            return .success(diskCached.response)
        }

        return await fetchFromNetwork(query: query, page: page, perPage: perPage, orientation: orientation, cacheKey: cacheKey)
    }

    // MARK: - Download Image Data

    func downloadImageData(from photo: UnsplashPhoto, quality: ImageQuality = .regular) async -> Result<Data, UnsplashProviderError> {
        let urlString: String
        switch quality {
        case .thumb: urlString = photo.urls.thumb
        case .small: urlString = photo.urls.small
        case .regular: urlString = photo.urls.regular
        case .full: urlString = photo.urls.full
        }

        if let cached = await diskCache.getImageData(for: urlString) {
            return .success(cached)
        }

        guard let url = URL(string: urlString) else {
            return .failure(.networkError("Invalid image URL."))
        }

        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return .failure(.networkError("Failed to download image."))
            }
            await diskCache.storeImageData(data, for: urlString)
            return .success(data)
        } catch {
            return .failure(.networkError(error.localizedDescription))
        }
    }

    // MARK: - Fetch by ID

    func photo(id: String) async -> Result<UnsplashPhoto, UnsplashProviderError> {
        guard let accessKey = resolveAccessKey() else {
            return .failure(.missingAPIKey)
        }

        guard let url = URL(string: "\(baseURL)/photos/\(id)") else {
            return .failure(.networkError("Invalid photo URL."))
        }

        var request = buildRequest(url: url, accessKey: accessKey)
        request.timeoutInterval = 15

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.networkError("Invalid response type."))
            }
            if let error = mapHTTPError(httpResponse.statusCode) { return .failure(error) }
            let photo = try JSONDecoder().decode(UnsplashPhoto.self, from: data)
            return .success(photo)
        } catch is DecodingError {
            return .failure(.decodingError("Response did not match expected Unsplash schema."))
        } catch let urlError as URLError {
            return .failure(.networkError(urlError.localizedDescription))
        } catch {
            return .failure(.networkError(error.localizedDescription))
        }
    }

    enum ImageQuality: Sendable {
        case thumb, small, regular, full
    }

    // MARK: - Private Networking

    private func fetchFromNetwork(
        query: String,
        page: Int,
        perPage: Int,
        orientation: String?,
        cacheKey: UnsplashCacheKey
    ) async -> Result<UnsplashSearchResponse, UnsplashProviderError> {
        if let inflight = await inflightTracker.existing(for: cacheKey) {
            return await inflight.value
        }

        let task = Task<Result<UnsplashSearchResponse, UnsplashProviderError>, Never> {
            let result = await performSearch(query: query, page: page, perPage: perPage, orientation: orientation)
            if case .success(let response) = result {
                let entry = UnsplashCacheEntry(response: response, timestamp: Date())
                await memoryCache.set(entry, for: cacheKey)
                await diskCache.set(entry, for: cacheKey)
            }
            await inflightTracker.remove(for: cacheKey)
            return result
        }

        await inflightTracker.register(task, for: cacheKey)
        return await task.value
    }

    private func refreshInBackground(
        query: String,
        page: Int,
        perPage: Int,
        orientation: String?,
        cacheKey: UnsplashCacheKey
    ) async {
        guard await inflightTracker.existing(for: cacheKey) == nil else { return }
        let result = await performSearch(query: query, page: page, perPage: perPage, orientation: orientation)
        if case .success(let response) = result {
            let entry = UnsplashCacheEntry(response: response, timestamp: Date())
            await memoryCache.set(entry, for: cacheKey)
            await diskCache.set(entry, for: cacheKey)
        }
    }

    private func performSearch(
        query: String,
        page: Int,
        perPage: Int,
        orientation: String?
    ) async -> Result<UnsplashSearchResponse, UnsplashProviderError> {
        guard let accessKey = resolveAccessKey() else {
            return .failure(.missingAPIKey)
        }

        guard var components = URLComponents(string: "\(baseURL)/search/photos") else {
            return .failure(.networkError("Invalid base URL."))
        }

        var queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)")
        ]
        if let orientation {
            queryItems.append(URLQueryItem(name: "orientation", value: orientation))
        }
        components.queryItems = queryItems

        guard let requestURL = components.url else {
            return .failure(.networkError("Failed to construct request URL."))
        }

        var request = buildRequest(url: requestURL, accessKey: accessKey)
        request.timeoutInterval = 15

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.networkError("Invalid response type."))
            }

            if let error = mapHTTPError(httpResponse.statusCode) {
                return .failure(error)
            }

            let decoder = JSONDecoder()
            let searchResponse = try decoder.decode(UnsplashSearchResponse.self, from: data)

            if searchResponse.results.isEmpty {
                return .failure(.noResults)
            }

            return .success(searchResponse)
        } catch is DecodingError {
            return .failure(.decodingError("Response did not match expected Unsplash schema."))
        } catch let urlError as URLError {
            return .failure(.networkError(urlError.localizedDescription))
        } catch {
            return .failure(.networkError(error.localizedDescription))
        }
    }

    private func resolveAccessKey() -> String? {
        guard let key = keyManager.unsplashAccessKey,
              !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return key
    }

    private func buildRequest(url: URL, accessKey: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("Client-ID \(accessKey)", forHTTPHeaderField: "Authorization")
        request.setValue("v1", forHTTPHeaderField: "Accept-Version")
        if let appID = keyManager.unsplashApplicationID,
           !appID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            request.setValue(appID, forHTTPHeaderField: "X-App-ID")
        }
        return request
    }

    private func mapHTTPError(_ statusCode: Int) -> UnsplashProviderError? {
        switch statusCode {
        case 200: return nil
        case 401: return .invalidAPIKey
        case 403, 429: return .rateLimited
        default:
            if statusCode >= 400 { return .serverError(statusCode) }
            return nil
        }
    }
}

// MARK: - Cache Types

struct UnsplashCacheKey: Hashable, Sendable {
    let query: String
    let page: Int
}

struct UnsplashCacheEntry: Codable, Sendable {
    let response: UnsplashSearchResponse
    let timestamp: Date

    var isStale: Bool {
        Date().timeIntervalSince(timestamp) > 300
    }
}

// MARK: - Memory Cache

actor UnsplashMemoryCache {
    private var store: [UnsplashCacheKey: UnsplashCacheEntry] = [:]
    private let maxEntries = 100

    func get(for key: UnsplashCacheKey) -> UnsplashCacheEntry? {
        store[key]
    }

    func set(_ entry: UnsplashCacheEntry, for key: UnsplashCacheKey) {
        if store.count >= maxEntries {
            let oldest = store.min(by: { $0.value.timestamp < $1.value.timestamp })
            if let oldestKey = oldest?.key {
                store.removeValue(forKey: oldestKey)
            }
        }
        store[key] = entry
    }
}

// MARK: - Disk Cache

actor UnsplashDiskCache {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    init() {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = caches.appendingPathComponent("UnsplashCache", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func get(for key: UnsplashCacheKey) -> UnsplashCacheEntry? {
        let url = fileURL(for: key)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(UnsplashCacheEntry.self, from: data)
    }

    func set(_ entry: UnsplashCacheEntry, for key: UnsplashCacheKey) {
        let url = fileURL(for: key)
        guard let data = try? JSONEncoder().encode(entry) else { return }
        try? data.write(to: url)
    }

    func getImageData(for urlString: String) -> Data? {
        let url = imageFileURL(for: urlString)
        return try? Data(contentsOf: url)
    }

    func storeImageData(_ data: Data, for urlString: String) {
        let url = imageFileURL(for: urlString)
        try? data.write(to: url)
    }

    private func fileURL(for key: UnsplashCacheKey) -> URL {
        let hash = "\(key.query.hashValue)_\(key.page)"
        return cacheDirectory.appendingPathComponent("search_\(hash).json")
    }

    private func imageFileURL(for urlString: String) -> URL {
        let hash = "\(urlString.hashValue)"
        return cacheDirectory.appendingPathComponent("img_\(hash).dat")
    }
}

// MARK: - Inflight Tracker

actor UnsplashInflightTracker {
    private var inflight: [UnsplashCacheKey: Task<Result<UnsplashSearchResponse, UnsplashProviderError>, Never>] = [:]

    func existing(for key: UnsplashCacheKey) -> Task<Result<UnsplashSearchResponse, UnsplashProviderError>, Never>? {
        inflight[key]
    }

    func register(_ task: Task<Result<UnsplashSearchResponse, UnsplashProviderError>, Never>, for key: UnsplashCacheKey) {
        inflight[key] = task
    }

    func remove(for key: UnsplashCacheKey) {
        inflight.removeValue(forKey: key)
    }
}
