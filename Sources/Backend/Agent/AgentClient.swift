import Foundation

/// Handles API communication with Jules.
final class AgentClient {
    static let shared = AgentClient()

    private let baseURL = URL(string: "https://jules.googleapis.com/v1alpha")!
    private let session = URLSession.shared
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let maxRetries = 3

    private init() {}

    private struct APIErrorEnvelope: Decodable {
        struct APIError: Decodable {
            let code: Int?
            let status: String?
            let message: String?
        }
        let error: APIError?
    }

    private enum RetryDisposition {
        case retry
        case noRetry
    }

    private func makeRequest(_ path: String, method: String = "GET", body: Encodable? = nil) throws -> URLRequest {
        guard let apiKey = julesAPIKey()?.trimmingCharacters(in: .whitespacesAndNewlines), !apiKey.isEmpty else {
            throw AgentError.missingApiKey
        }

        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }

    private func perform(_ request: URLRequest, acceptedStatusCodes: ClosedRange<Int> = 200...299) async throws -> Data {
        var attempt = 0
        var latestError: Error?

        while attempt < maxRetries {
            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else { throw AgentError.invalidResponse }
                if acceptedStatusCodes.contains(http.statusCode) { return data }

                let message = parseAPIError(data)
                if http.statusCode == 400 || http.statusCode == 401 || http.statusCode == 403 || http.statusCode == 404 {
                    throw AgentError.apiError("HTTP \(http.statusCode): \(message)")
                }

                if shouldRetry(statusCode: http.statusCode) == .retry {
                    attempt += 1
                    if attempt < maxRetries {
                        try await Task.sleep(for: .seconds(Double(attempt)))
                        continue
                    }
                }

                throw AgentError.apiError("HTTP \(http.statusCode): \(message)")
            } catch {
                latestError = error
                if error is CancellationError { throw error }
                if let agentError = error as? AgentError, !agentError.isRetriable {
                    throw agentError
                }
                attempt += 1
                if attempt < maxRetries {
                    try await Task.sleep(for: .seconds(Double(attempt)))
                }
            }
        }

        throw latestError ?? AgentError.invalidResponse
    }

    private func shouldRetry(statusCode: Int) -> RetryDisposition {
        (statusCode == 429 || (500...599).contains(statusCode)) ? .retry : .noRetry
    }

    private func parseAPIError(_ data: Data) -> String {
        if let payload = try? decoder.decode(APIErrorEnvelope.self, from: data),
           let error = payload.error {
            return "[\(error.status ?? "UNKNOWN") #\(error.code.map(String.init) ?? "?")] \(error.message ?? "No message")"
        }
        return String(data: data, encoding: .utf8) ?? "Unknown API error"
    }

    private func julesAPIKey() -> String? {
        if let key = APIKeyManager.shared.getKey(for: "jules"), !key.isEmpty {
            return key
        }
        if let legacy = AgentKeychainManager.shared.getKey(), !legacy.isEmpty {
            return legacy
        }
        return nil
    }

    func validateKey() async throws -> Bool {
        let request = try makeRequest("sources")
        _ = try await perform(request)
        return true
    }

    func fetchSources() async throws -> [AgentSource] {
        let request = try makeRequest("sources")
        let data = try await perform(request)
        let response = try decoder.decode(AgentSourcesResponse.self, from: data)
        return response.sources ?? []
    }

    func createSession(prompt: String, source: String, branch: String?) async throws -> AgentSession {
        let sanitizedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedSource = source.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedBranch = branch?.trimmingCharacters(in: .whitespacesAndNewlines)

        var invalidFields: [String] = []
        if sanitizedPrompt.isEmpty { invalidFields.append("prompt") }
        if sanitizedSource.isEmpty { invalidFields.append("sourceContext.source") }
        if let sanitizedBranch, sanitizedBranch.isEmpty { invalidFields.append("sourceContext.githubRepoContext.startingBranch") }
        if !invalidFields.isEmpty {
            print("[AgentClient] Invalid createSession payload fields: \(invalidFields.joined(separator: ", "))")
            throw AgentError.invalidPayload(invalidFields)
        }

        struct CreateSessionPayload: Encodable {
            let prompt: String
            let sourceContext: AgentSourceContext
            let automationMode: String = "AUTO_CREATE_PR"
        }

        let payload = CreateSessionPayload(
            prompt: sanitizedPrompt,
            sourceContext: AgentSourceContext(
                source: sanitizedSource,
                githubRepoContext: sanitizedBranch.map { AgentGitHubRepoContext(startingBranch: $0) }
            )
        )

        let request = try makeRequest("sessions", method: "POST", body: payload)
        let data = try await perform(request)
        return try decoder.decode(AgentSession.self, from: data)
    }

    func resolveGitHubSource(owner: String, repo: String) async throws -> String {
        let cleanedOwner = owner.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedRepo = repo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedOwner.isEmpty, !cleanedRepo.isEmpty else {
            throw AgentError.invalidPayload(["owner", "repo"])
        }

        let sources = try await fetchSources()
        if let matched = sources.first(where: {
            $0.githubRepo?.owner.caseInsensitiveCompare(cleanedOwner) == .orderedSame &&
            $0.githubRepo?.repo.caseInsensitiveCompare(cleanedRepo) == .orderedSame
        }) {
            return matched.name
        }
        return "sources/github/\(cleanedOwner)/\(cleanedRepo)"
    }

    func getSession(id: String) async throws -> AgentSession {
        let request = try makeRequest("sessions/\(id)")
        let data = try await perform(request)
        return try decoder.decode(AgentSession.self, from: data)
    }

    func fetchActivities(sessionId: String) async throws -> [AgentActivity] {
        let request = try makeRequest("sessions/\(sessionId)/activities")
        let data = try await perform(request)

        let customDecoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"

        customDecoder.dateDecodingStrategy = .custom({ decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            if let date = formatter.date(from: dateStr) { return date }
            let isoFormatter = ISO8601DateFormatter()
            if let date = isoFormatter.date(from: dateStr) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateStr)")
        })

        let responseObj = try customDecoder.decode(AgentActivitiesResponse.self, from: data)
        return responseObj.activities ?? []
    }

    func listSessions() async throws -> [AgentSession] {
        let request = try makeRequest("sessions")
        let data = try await perform(request)
        let response = try decoder.decode(AgentSessionsResponse.self, from: data)
        return response.sessions ?? []
    }
}

private struct AnyEncodable: Encodable {
    private let wrapped: (Encoder) throws -> Void

    init(_ encodable: Encodable) {
        wrapped = encodable.encode
    }

    func encode(to encoder: Encoder) throws {
        try wrapped(encoder)
    }
}

enum AgentError: Error, LocalizedError {
    case missingApiKey
    case invalidResponse
    case invalidPayload([String])
    case apiError(String)

    var isRetriable: Bool {
        switch self {
        case .missingApiKey, .invalidPayload:
            return false
        case .invalidResponse, .apiError:
            return true
        }
    }

    var errorDescription: String? {
        switch self {
        case .missingApiKey: return "Jules API key is missing. Please set it in Settings."
        case .invalidResponse: return "Received an invalid response from the Jules API."
        case .invalidPayload(let fields): return "Invalid request payload fields: \(fields.joined(separator: ", "))."
        case .apiError(let message): return message
        }
    }
}
