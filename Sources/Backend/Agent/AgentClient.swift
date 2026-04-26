import Foundation

/// Handles API communication with Jules.
final class AgentClient {
    static let shared = AgentClient()

    private let requestManager: JulesRequestManager
    private let maxRetries = 3

    private init(requestManager: JulesRequestManager = .shared) {
        self.requestManager = requestManager
    }

    private enum RetryDisposition {
        case retry
        case noRetry
    }

    private func performWithRetry<Response: Decodable>(
        path: String,
        method: String = "GET"
    ) async throws -> Response {
        var attempt = 0
        var latestError: Error?

        while attempt < maxRetries {
            do {
                return try await requestManager.send(path: path, method: method) as Response
            } catch {
                latestError = error
                if error is CancellationError { throw error }

                if let mapped = mapError(error), !mapped.isRetriable {
                    throw mapped
                }

                if shouldRetry(error: error) == .noRetry {
                    throw mapError(error) ?? error
                }

                attempt += 1
                if attempt < maxRetries {
                    try await Task.sleep(for: .seconds(Double(attempt)))
                }
            }
        }

        throw mapError(latestError) ?? latestError ?? AgentError.invalidResponse
    }

    private func performWithRetry<Response: Decodable, Body: Encodable & JulesPayloadValidating>(
        path: String,
        method: String = "GET",
        body: Body
    ) async throws -> Response {
        var attempt = 0
        var latestError: Error?

        while attempt < maxRetries {
            do {
                return try await requestManager.send(path: path, method: method, body: body) as Response
            } catch {
                latestError = error
                if error is CancellationError { throw error }

                if let mapped = mapError(error), !mapped.isRetriable {
                    throw mapped
                }

                if shouldRetry(error: error) == .noRetry {
                    throw mapError(error) ?? error
                }

                attempt += 1
                if attempt < maxRetries {
                    try await Task.sleep(for: .seconds(Double(attempt)))
                }
            }
        }

        throw mapError(latestError) ?? latestError ?? AgentError.invalidResponse
    }

    private func shouldRetry(error: Error) -> RetryDisposition {
        if let requestError = error as? JulesRequestManager.JulesRequestError,
           case .apiError(let statusCode, _, _) = requestError {
            return (statusCode == 429 || (500...599).contains(statusCode)) ? .retry : .noRetry
        }
        if let agentError = error as? AgentError {
            return agentError.isRetriable ? .retry : .noRetry
        }
        return .retry
    }

    private func mapError(_ error: Error?) -> AgentError? {
        guard let error else { return nil }
        if let agentError = error as? AgentError { return agentError }
        if let requestError = error as? JulesRequestManager.JulesRequestError {
            switch requestError {
            case .missingOrInvalidAPIKey:
                return .missingApiKey
            case .invalidPayload(let fields):
                return .invalidPayload(fields.map { "\($0.field): \($0.reason)" })
            case .invalidRepositoryURL(let reason):
                return .invalidPayload(["repositoryUrl: \(reason)"])
            case .invalidResponse:
                return .invalidResponse
            case .apiError(_, let message, let fieldFailures):
                if !fieldFailures.isEmpty {
                    let detail = fieldFailures.map { "\($0.field): \($0.reason)" }.joined(separator: "; ")
                    return .apiError("\(message) | \(detail)")
                }
                return .apiError(message)
            }
        }
        return .apiError(error.localizedDescription)
    }

    func validateKey() async throws -> Bool {
        let _: AgentSourcesResponse = try await performWithRetry(path: "sources")
        return true
    }

    func fetchSources() async throws -> [AgentSource] {
        let response: AgentSourcesResponse = try await performWithRetry(path: "sources")
        return response.sources ?? []
    }

    func createSession(prompt: String, owner: String, repo: String, branch: String?) async throws -> AgentSession {
        let sourceName = try await resolveGitHubSource(owner: owner, repo: repo)
        let repositoryURL = "https://github.com/\(owner.trimmingCharacters(in: .whitespacesAndNewlines))/\(repo.trimmingCharacters(in: .whitespacesAndNewlines))"

        print("[AgentClient] Building createSession payload")
        print("[AgentClient] repositoryUrl: \(repositoryURL)")
        print("[AgentClient] prompt length: \(prompt.trimmingCharacters(in: .whitespacesAndNewlines).count)")

        let payload = try AgentCreateSessionRequest(
            prompt: prompt,
            source: sourceName,
            branch: branch,
            repositoryURL: repositoryURL,
            automationMode: "AUTO_CREATE_PR"
        )

        do {
            let session: AgentSession = try await performWithRetry(path: "sessions", method: "POST", body: payload)
            return session
        } catch let requestError as JulesRequestManager.JulesRequestError {
            if case .apiError(let statusCode, let message, _) = requestError,
               statusCode == 404,
               message.localizedCaseInsensitiveContains("NOT_FOUND"),
               let recovered = try await recoverSessionAfterNotFound(prompt: payload.prompt, source: payload.sourceContext.source) {
                return recovered
            }
            throw mapError(requestError) ?? requestError
        } catch {
            throw error
        }
    }

    private func recoverSessionAfterNotFound(prompt: String, source: String) async throws -> AgentSession? {
        for _ in 0..<4 {
            let sessions = try await listSessions()
            if let session = sessions.first(where: {
                ($0.prompt?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") == prompt &&
                $0.sourceContext.source == source
            }) {
                return session
            }
            try await Task.sleep(for: .seconds(1.5))
        }
        return nil
    }

    func resolveGitHubSource(owner: String, repo: String) async throws -> String {
        let cleanedOwner = owner.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedRepo = repo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedOwner.isEmpty, !cleanedRepo.isEmpty else {
            throw AgentError.invalidPayload(["owner", "repo"])
        }

        let repositoryURL = "https://github.com/\(cleanedOwner)/\(cleanedRepo)"
        _ = try requestManager.validateRepositoryURL(repositoryURL)

        print("[AgentClient] Resolving source for repositoryUrl: \(repositoryURL)")
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
        try await performWithRetry(path: "sessions/\(id)")
    }

    func fetchActivities(sessionId: String) async throws -> [AgentActivity] {
        let dataResponse: AgentActivitiesResponse = try await performWithRetry(path: "sessions/\(sessionId)/activities")
        return dataResponse.activities ?? []
    }

    func listSessions() async throws -> [AgentSession] {
        let response: AgentSessionsResponse = try await performWithRetry(path: "sessions")
        return response.sessions ?? []
    }
}


private struct AgentCreateSessionRequest: Encodable, JulesPayloadValidating {
    let prompt: String
    let sourceContext: SourceContext
    let automationMode: String

    struct SourceContext: Encodable {
        let source: String
        let githubRepoContext: GitHubRepoContext

        struct GitHubRepoContext: Encodable {
            let startingBranch: String
        }
    }

    init(prompt: String, source: String, branch: String?, repositoryURL: String, automationMode: String) throws {
        self.prompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        self.sourceContext = .init(
            source: source.trimmingCharacters(in: .whitespacesAndNewlines),
            githubRepoContext: .init(startingBranch: (branch?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? branch!.trimmingCharacters(in: .whitespacesAndNewlines) : "main"))
        )
        self.automationMode = automationMode
        _ = try JulesRequestManager.shared.validateRepositoryURL(repositoryURL)
    }

    func validationErrors() -> [JulesRequestManager.FieldValidationError] {
        var issues: [JulesRequestManager.FieldValidationError] = []

        if prompt.isEmpty {
            issues.append(.init(field: "prompt", reason: "Prompt must be non-empty after trimming whitespace"))
        }
        if sourceContext.source.isEmpty {
            issues.append(.init(field: "sourceContext.source", reason: "Source must be non-empty"))
        }
        if sourceContext.githubRepoContext.startingBranch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.init(field: "sourceContext.githubRepoContext.startingBranch", reason: "Starting branch must be non-empty"))
        }
        if automationMode != "AUTO_CREATE_PR" && automationMode != "NO_AUTOMATION" {
            issues.append(.init(field: "automationMode", reason: "Unsupported automation mode \(automationMode)"))
        }

        return issues
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
        case .missingApiKey: return "Missing or invalid Jules API key"
        case .invalidResponse: return "Received an invalid response from the Jules API."
        case .invalidPayload(let fields): return "Invalid request payload fields: \(fields.joined(separator: ", "))."
        case .apiError(let message): return message
        }
    }
}
