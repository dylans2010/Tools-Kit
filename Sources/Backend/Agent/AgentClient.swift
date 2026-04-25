import Foundation

/// Handles API communication with Jules.
final class AgentClient {
    static let shared = AgentClient()

    private let baseURL = URL(string: "https://jules.googleapis.com/v1alpha")!
    private let session = URLSession.shared

    private init() {}

    private func makeRequest(_ path: String, method: String = "GET", body: Encodable? = nil) throws -> URLRequest {
        guard let apiKey = AgentKeychainManager.shared.getKey() else {
            throw AgentError.missingApiKey
        }

        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        return request
    }

    func validateKey() async throws -> Bool {
        let request = try makeRequest("sources")
        let (_, response) = try await session.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            return httpResponse.statusCode == 200
        }
        return false
    }

    func fetchSources() async throws -> [AgentSource] {
        let request = try makeRequest("sources")
        let (data, _) = try await session.data(for: request)
        let decoder = JSONDecoder()
        let response = try decoder.decode(AgentSourcesResponse.self, from: data)
        return response.sources ?? []
    }

    func createSession(prompt: String, source: String, branch: String?) async throws -> AgentSession {
        struct CreateSessionPayload: Encodable {
            let prompt: String
            let sourceContext: AgentSourceContext
            let automationMode: String = "AUTO_CREATE_PR"
        }

        let payload = CreateSessionPayload(
            prompt: prompt,
            sourceContext: AgentSourceContext(
                source: source,
                githubRepoContext: branch.map { AgentGitHubRepoContext(startingBranch: $0) }
            )
        )

        let request = try makeRequest("sessions", method: "POST", body: payload)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(AgentSession.self, from: data)
    }

    func getSession(id: String) async throws -> AgentSession {
        let request = try makeRequest("sessions/\(id)")
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(AgentSession.self, from: data)
    }

    func fetchActivities(sessionId: String) async throws -> [AgentActivity] {
        let request = try makeRequest("sessions/\(sessionId)/activities")
        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw AgentError.apiError("API returned status code \(httpResponse.statusCode)")
        }

        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ" // Support fractional seconds

        decoder.dateDecodingStrategy = .custom({ decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)

            // Try fractional first, then standard ISO8601
            if let date = formatter.date(from: dateStr) { return date }

            let isoFormatter = ISO8601DateFormatter()
            if let date = isoFormatter.date(from: dateStr) { return date }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateStr)")
        })

        let responseObj = try decoder.decode(AgentActivitiesResponse.self, from: data)
        return responseObj.activities ?? []
    }

    func listSessions() async throws -> [AgentSession] {
        let request = try makeRequest("sessions")
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(AgentSessionsResponse.self, from: data)
        return response.sessions ?? []
    }
}

enum AgentError: Error, LocalizedError {
    case missingApiKey
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .missingApiKey: return "Jules API key is missing. Please set it in Settings."
        case .invalidResponse: return "Received an invalid response from the Jules API."
        case .apiError(let message): return message
        }
    }
}
