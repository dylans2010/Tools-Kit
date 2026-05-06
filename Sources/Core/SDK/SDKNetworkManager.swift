import Foundation

public final class SDKNetworkManager {
    public static let shared = SDKNetworkManager()

    private let session: URLSession
    private let rateLimiter = RateLimiter()
    private let maxRetries = 3

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 120
        config.waitsForConnectivity = true
        config.httpMaximumConnectionsPerHost = 6
        session = URLSession(configuration: config)
    }

    // MARK: - Fetch

    public func fetch(url urlString: String, headers: [String: String] = [:]) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw SDKError.executionFailed(reason: "Invalid URL: \(urlString)")
        }

        try await rateLimiter.waitForSlot(domain: url.host ?? "unknown")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }

        return try await executeWithRetry(request: request)
    }

    // MARK: - POST

    public func post(url urlString: String, body: Data, headers: [String: String] = [:]) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw SDKError.executionFailed(reason: "Invalid URL: \(urlString)")
        }

        try await rateLimiter.waitForSlot(domain: url.host ?? "unknown")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }

        return try await executeWithRetry(request: request)
    }

    // MARK: - Webhook

    public func postWebhook(url urlString: String, payload: [String: Any], apiKey: String? = nil) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw SDKError.executionFailed(reason: "Invalid Webhook URL")
        }

        try await rateLimiter.waitForSlot(domain: url.host ?? "unknown")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = apiKey {
            request.addValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        return try await executeWithRetry(request: request)
    }

    // MARK: - Private

    private func executeWithRetry(request: URLRequest, attempt: Int = 0) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw SDKError.executionFailed(reason: "Invalid response")
            }

            if httpResponse.statusCode == 429 {
                let retryAfter = Double(httpResponse.value(forHTTPHeaderField: "Retry-After") ?? "5") ?? 5
                SDKLogStore.shared.log("Rate limited. Retrying after \(retryAfter)s", source: "SDKNetworkManager", level: .warning)
                try await Task.sleep(nanoseconds: UInt64(retryAfter * 1_000_000_000))
                return try await executeWithRetry(request: request, attempt: attempt + 1)
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                if attempt < maxRetries && httpResponse.statusCode >= 500 {
                    let delay = pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    return try await executeWithRetry(request: request, attempt: attempt + 1)
                }
                throw SDKError.executionFailed(reason: "HTTP \(httpResponse.statusCode)")
            }

            SDKLogStore.shared.log("Request succeeded: \(request.url?.absoluteString ?? "")", source: "SDKNetworkManager", level: .debug)
            return data
        } catch let error as SDKError {
            throw error
        } catch {
            if attempt < maxRetries {
                let delay = pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                SDKLogStore.shared.log("Network error, retrying (attempt \(attempt + 1)): \(error.localizedDescription)", source: "SDKNetworkManager", level: .warning)
                return try await executeWithRetry(request: request, attempt: attempt + 1)
            }
            throw SDKError.executionFailed(reason: "Network error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Rate Limiter

private actor RateLimiter {
    private var domainTimestamps: [String: [Date]] = [:]
    private let maxRequestsPerSecond = 10

    func waitForSlot(domain: String) async throws {
        let now = Date()
        var timestamps = domainTimestamps[domain] ?? []
        timestamps = timestamps.filter { now.timeIntervalSince($0) < 1.0 }

        if timestamps.count >= maxRequestsPerSecond {
            let oldestInWindow = timestamps.first!
            let waitTime = 1.0 - now.timeIntervalSince(oldestInWindow)
            if waitTime > 0 {
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
        }

        timestamps.append(Date())
        domainTimestamps[domain] = timestamps
    }
}
