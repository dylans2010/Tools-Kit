import Foundation

/// A reusable API client for GitHub.
final class GitHubAPIClient {
    static let shared = GitHubAPIClient()

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    /// Errors specific to GitHub API.
    enum APIError: LocalizedError {
        case unauthorized
        case forbidden(String) // Often rate limit
        case notFound
        case decodingError(Error)
        case networkError(Error)
        case invalidResponse
        case serverError(Int)

        var errorDescription: String? {
            switch self {
            case .unauthorized: return "Invalid GitHub token."
            case .forbidden(let reason): return "Access forbidden: \(reason)"
            case .notFound: return "Resource not found."
            case .decodingError(let error): return "Failed to decode response: \(error.localizedDescription)"
            case .networkError(let error): return "Network error: \(error.localizedDescription)"
            case .invalidResponse: return "Invalid response from GitHub."
            case .serverError(let code): return "GitHub server error (Status: \(code))."
            }
        }
    }

    /// Performs a request to GitHub API.
    /// - Parameters:
    ///   - endpoint: The endpoint to hit.
    ///   - body: Optional Encodable body.
    /// - Returns: Decoded model.
    func request<T: Decodable>(_ endpoint: GitHubEndpoints, body: Encodable? = nil) async throws -> T {
        let request = try buildRequest(for: endpoint, body: body)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            // Handle Rate Limits via headers if needed
            if let rateLimitRemaining = httpResponse.allHeaderFields["x-ratelimit-remaining"] as? String {
                #if DEBUG
                print("[GitHubAPI] Rate Limit Remaining: \(rateLimitRemaining)")
                #endif
            }

            switch httpResponse.statusCode {
            case 200...299:
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw APIError.decodingError(error)
                }
            case 401:
                throw APIError.unauthorized
            case 403:
                let message = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String ?? "Rate limit exceeded or insufficient permissions."
                throw APIError.forbidden(message)
            case 404:
                throw APIError.notFound
            default:
                throw APIError.serverError(httpResponse.statusCode)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    /// Specialized request for endpoints that return no body (e.g., Star/Unstar).
    func requestEmpty(_ endpoint: GitHubEndpoints, body: Encodable? = nil) async throws {
        let request = try buildRequest(for: endpoint, body: body)
        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 { throw APIError.unauthorized }
        if httpResponse.statusCode == 403 { throw APIError.forbidden("Forbidden") }
        if httpResponse.statusCode == 404 { throw APIError.notFound }
        if !(200...299).contains(httpResponse.statusCode) {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }

    private func buildRequest(for endpoint: GitHubEndpoints, body: Encodable? = nil) throws -> URLRequest {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = endpoint.method

        guard let token = GitHubAuthManager.shared.getToken() else {
            throw APIError.unauthorized
        }

        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Tools-Kit-iOS", forHTTPHeaderField: "User-Agent")

        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        return request
    }
}
