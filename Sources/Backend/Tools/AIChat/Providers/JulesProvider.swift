import Foundation

// MARK: - Jules AI Provider

final class JulesProvider: AIProvider {
    let id = "jules"
    let name = "Jules (Google)"
    let icon = "brain.head.profile"
    let apiKeyURL = URL(string: "https://jules.google.com/settings/api")
    let apiKeyPlaceholder = "X-Goog-Api-Key..."

    let models: [AIModel] = [
        AIModel(id: "jules-v1", name: "Jules Agent (Alpha)", supportsVision: false)
    ]

    private let baseURL = URL(string: "https://jules.googleapis.com/v1alpha")!
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    static var apiProviderInfo: (id: String, name: String, apiKeyPlaceholder: String) {
        ("jules", "Jules", "X-Goog-Api-Key...")
    }

    func supportsVision(model: String) -> Bool { false }

    func send(messages: [ChatMessage], model: String, apiKey: String) async throws -> String {
        let prompt = messages.last?.content ?? ""
        let session = try await createSession(prompt: prompt, source: nil, apiKey: apiKey)
        return "AGENT_SESSION_ID:\(session.id)"
    }

    func sendWithAttachments(messages: [ChatMessage], attachments: [ChatAttachment], model: String, apiKey: String) async throws -> String {
        throw AIProviderError.unsupportedFeature("Attachments not supported in Jules API yet.")
    }

    func validateAPIKey(_ key: String) async throws -> Bool {
        do {
            _ = try await listSources(apiKey: key)
            return true
        } catch {
            return false
        }
    }

    func fetchModels(apiKey: String) async throws -> [AIModel] { models }

    struct Source: Codable, Identifiable {
        let name: String
        let id: String
        let githubRepo: GitHubRepo?

        struct GitHubRepo: Codable {
            let owner: String
            let repo: String
        }
    }

    struct Session: Codable, Identifiable {
        let name: String
        let id: String
        let title: String?
        let prompt: String
        let outputs: [Output]?

        struct Output: Codable { let pullRequest: PullRequest? }
        struct PullRequest: Codable { let url: String; let title: String; let description: String }
    }

    private struct SourceListResponse: Codable { let sources: [Source] }

    private struct CreateSessionRequest: Encodable {
        let prompt: String
        let sourceContext: SourceContext?
        let automationMode: String

        struct SourceContext: Encodable {
            let source: String
            let githubRepoContext: GitHubRepoContext

            struct GitHubRepoContext: Encodable {
                let startingBranch: String
            }
        }
    }

    private struct JulesErrorResponse: Codable {
        struct APIError: Codable {
            let code: Int?
            let message: String?
            let status: String?
        }
        let error: APIError?
    }

    enum ValidationError: Error, LocalizedError {
        case invalidAPIKeyHeader
        case invalidPrompt
        case invalidSource
        case invalidAutomationMode(String)

        var errorDescription: String? {
            switch self {
            case .invalidAPIKeyHeader: return "Jules API key is missing or empty."
            case .invalidPrompt: return "prompt must be non-empty."
            case .invalidSource: return "sourceContext.source must be non-empty when provided."
            case .invalidAutomationMode(let mode): return "automationMode \(mode) is invalid."
            }
        }
    }

    private let allowedAutomationModes: Set<String> = ["AUTO_CREATE_PR", "NO_AUTOMATION"]

    private func validateCreateSession(prompt: String, source: String?, automationMode: String) throws {
        var invalidFields: [String] = []
        if prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { invalidFields.append("prompt") }
        if let source, source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { invalidFields.append("sourceContext.source") }
        if !allowedAutomationModes.contains(automationMode) { invalidFields.append("automationMode") }
        if !invalidFields.isEmpty {
            print("[JulesProvider] Invalid createSession payload fields: \(invalidFields.joined(separator: ", "))")
            if invalidFields.contains("prompt") { throw ValidationError.invalidPrompt }
            if invalidFields.contains("sourceContext.source") { throw ValidationError.invalidSource }
            throw ValidationError.invalidAutomationMode(automationMode)
        }
    }

    private func buildRequest(path: String, method: String = "GET", apiKey: String, body: Data? = nil) throws -> URLRequest {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { throw ValidationError.invalidAPIKeyHeader }

        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue(trimmedKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        return request
    }

    private func parseErrorMessage(_ data: Data) -> String {
        if let parsed = try? decoder.decode(JulesErrorResponse.self, from: data),
           let error = parsed.error {
            let status = error.status ?? "UNKNOWN"
            let code = error.code.map(String.init) ?? "?"
            let message = error.message ?? "No message"
            return "[\(status) #\(code)] \(message)"
        }
        return String(data: data, encoding: .utf8) ?? "Unknown error"
    }

    func listSources(apiKey: String) async throws -> [Source] {
        let request = try buildRequest(path: "sources", apiKey: apiKey)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AIProviderError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw AIProviderError.networkError(parseErrorMessage(data))
        }
        return try decoder.decode(SourceListResponse.self, from: data).sources
    }

    func createSession(prompt: String, source: String?, apiKey: String, automationMode: String = "AUTO_CREATE_PR") async throws -> Session {
        try validateCreateSession(prompt: prompt, source: source, automationMode: automationMode)

        let body = CreateSessionRequest(
            prompt: prompt.trimmingCharacters(in: .whitespacesAndNewlines),
            sourceContext: source.map {
                .init(source: $0, githubRepoContext: .init(startingBranch: "main"))
            },
            automationMode: automationMode
        )
        let request = try buildRequest(path: "sessions", method: "POST", apiKey: apiKey, body: try encoder.encode(body))

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AIProviderError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw AIProviderError.networkError(parseErrorMessage(data))
        }

        return try decoder.decode(Session.self, from: data)
    }

    func getSession(id: String, apiKey: String) async throws -> Session {
        let request = try buildRequest(path: "sessions/\(id)", apiKey: apiKey)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AIProviderError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw AIProviderError.networkError(parseErrorMessage(data))
        }
        return try decoder.decode(Session.self, from: data)
    }

    func approvePlan(sessionID: String, apiKey: String) async throws {
        let request = try buildRequest(path: "sessions/\(sessionID):approvePlan", method: "POST", apiKey: apiKey)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AIProviderError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw AIProviderError.networkError(parseErrorMessage(data))
        }
    }
}
