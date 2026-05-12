import Foundation

enum NetworkMiddlewareDecision: Sendable {
    case allow
    case block(String)
}

protocol NetworkMiddleware {
    func process(request: inout URLRequest) -> NetworkMiddlewareDecision
}

final class NetworkClient {
    nonisolated(unsafe) static let shared = NetworkClient()

    private var middlewares: [NetworkMiddleware] = []
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    func addMiddleware(_ middleware: NetworkMiddleware) {
        middlewares.append(middleware)
    }

    func removeAllMiddlewares() {
        middlewares.removeAll()
    }

    func data(for request: URLRequest, retries: Int = 2) async throws -> (Data, URLResponse) {
        var mutableRequest = request
        for middleware in middlewares {
            switch middleware.process(request: &mutableRequest) {
            case .block(let reason):
                throw NetworkClientError.blocked(reason)
            case .allow:
                break
            }
        }
        return try await performWithRetry(request: mutableRequest, retries: retries)
    }

    private func performWithRetry(request: URLRequest, retries: Int) async throws -> (Data, URLResponse) {
        var lastError: Error?
        for attempt in 0...retries {
            do {
                let result = try await session.data(for: request)
                return result
            } catch {
                lastError = error
                if attempt < retries {
                    try await Task.sleep(nanoseconds: UInt64(500_000_000 * (attempt + 1)))
                }
            }
        }
        throw lastError ?? NetworkClientError.unknown
    }
}

enum NetworkClientError: LocalizedError, Sendable {
    case blocked(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .blocked(let reason): return "Request blocked: \(reason)"
        case .unknown: return "An unknown network error occurred"
        }
    }
}

extension LoggingMiddleware: NetworkMiddleware {
    func process(request: inout URLRequest) -> NetworkMiddlewareDecision {
        #if DEBUG
        print("[NetworkClient] \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        #endif
        return .allow
    }
}

final class TrackerBlockingMiddleware: NetworkMiddleware {
    private let blocklist: Set<String>

    init(blocklist: Set<String>) {
        self.blocklist = blocklist
    }

    func process(request: inout URLRequest) -> NetworkMiddlewareDecision {
        guard let host = request.url?.host else { return .allow }
        let lowercasedHost = host.lowercased()
        for blocked in blocklist {
            if lowercasedHost == blocked || lowercasedHost.hasSuffix(".\(blocked)") {
                return .block("Tracker domain: \(blocked)")
            }
        }
        return .allow
    }
}

final class RoutingMiddleware: NetworkMiddleware {
    var routerBaseURL: String

    init(routerBaseURL: String) {
        self.routerBaseURL = routerBaseURL
    }

    func process(request: inout URLRequest) -> NetworkMiddlewareDecision {
        guard !routerBaseURL.isEmpty,
              let originalURL = request.url,
              var components = URLComponents(string: routerBaseURL) else {
            return .allow
        }
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "url", value: originalURL.absoluteString))
        components.queryItems = queryItems
        if let routedURL = components.url {
            request.url = routedURL
        }
        return .allow
    }
}
