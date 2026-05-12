import Foundation

actor RadioService {
    nonisolated(unsafe) static let shared = RadioService()

    private let baseURL = "https://de1.api.radio-browser.info/json"
    private let session: URLSession
    private var cache: [String: (stations: [RadioStation], timestamp: Date)] = [:]
    private let cacheTTL: TimeInterval = 300

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.httpAdditionalHeaders = ["User-Agent": "ToolsKitApp/1.0"]
        self.session = URLSession(configuration: config)
    }

    // MARK: - Search

    func searchStations(query: String, offset: Int = 0, limit: Int = 30) async throws -> [RadioStation] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        var comps = URLComponents(string: "\(baseURL)/stations/search")!
        comps.queryItems = queryItems(offset: offset, limit: limit, extra: [
            URLQueryItem(name: "name", value: query)
        ])
        return try await fetch(url: comps.url!)
    }

    // MARK: - Top / Trending

    func fetchTopStations(offset: Int = 0, limit: Int = 30) async throws -> [RadioStation] {
        let key = "top_\(offset)_\(limit)"
        if let hit = cache[key], Date().timeIntervalSince(hit.timestamp) < cacheTTL {
            return hit.stations
        }
        var comps = URLComponents(string: "\(baseURL)/stations")!
        comps.queryItems = queryItems(offset: offset, limit: limit)
        let stations = try await fetch(url: comps.url!)
        cache[key] = (stations, Date())
        return stations
    }

    // MARK: - Filter

    func fetchByTag(tag: String, offset: Int = 0, limit: Int = 30) async throws -> [RadioStation] {
        let encoded = tag.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? tag
        var comps = URLComponents(string: "\(baseURL)/stations/bytag/\(encoded)")!
        comps.queryItems = queryItems(offset: offset, limit: limit)
        return try await fetch(url: comps.url!)
    }

    func fetchByCountry(country: String, offset: Int = 0, limit: Int = 30) async throws -> [RadioStation] {
        let encoded = country.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? country
        var comps = URLComponents(string: "\(baseURL)/stations/bycountry/\(encoded)")!
        comps.queryItems = queryItems(offset: offset, limit: limit)
        return try await fetch(url: comps.url!)
    }

    func fetchByLanguage(language: String, offset: Int = 0, limit: Int = 30) async throws -> [RadioStation] {
        let encoded = language.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? language
        var comps = URLComponents(string: "\(baseURL)/stations/bylanguage/\(encoded)")!
        comps.queryItems = queryItems(offset: offset, limit: limit)
        return try await fetch(url: comps.url!)
    }

    // MARK: - URL Validation

    func validateStreamURL(_ urlString: String) async -> Bool {
        guard let url = URL(string: urlString), !urlString.isEmpty else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 8
        do {
            let (_, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse {
                return (200...302).contains(http.statusCode)
            }
            return true
        } catch {
            return false
        }
    }

    // MARK: - Private

    private func queryItems(offset: Int, limit: Int, extra: [URLQueryItem] = []) -> [URLQueryItem] {
        var items: [URLQueryItem] = extra
        items += [
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "hidebroken", value: "true"),
            URLQueryItem(name: "order", value: "votes"),
            URLQueryItem(name: "reverse", value: "true")
        ]
        return items
    }

    private func fetch(url: URL) async throws -> [RadioStation] {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw RadioError.invalidResponse
        }
        return try JSONDecoder().decode([RadioStation].self, from: data)
    }
}

// MARK: - Errors

enum RadioError: LocalizedError, Sendable {
    case invalidResponse
    case invalidURL
    case streamUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from Radio Browser API"
        case .invalidURL: return "Invalid stream URL"
        case .streamUnavailable: return "Stream is currently unavailable"
        }
    }
}
