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

    private let baseURL = "https://jules.googleapis.com/v1alpha"

    func supportsVision(model: String) -> Bool {
        return false
    }

    func send(messages: [ChatMessage], model: String, apiKey: String) async throws -> String {
        // Jules is session-based. For standard send, we create a temporary session.
        let prompt = messages.last?.content ?? ""
        let session = try await createSession(prompt: prompt, source: nil, apiKey: apiKey)

        // For Agent Mode integration, we return the session ID as a handle
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

    func fetchModels(apiKey: String) async throws -> [AIModel] {
        return models
    }

    // MARK: - Jules Specific API

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

        struct Output: Codable {
            let pullRequest: PullRequest?
        }

        struct PullRequest: Codable {
            let url: String
            let title: String
            let description: String
        }
    }

    func listSources(apiKey: String) async throws -> [Source] {
        let url = URL(string: "\(baseURL)/sources")!
        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AIProviderError.invalidAPIKey
        }

        let result = try JSONDecoder().decode([String: [Source]].self, from: data)
        return result["sources"] ?? []
    }

    func createSession(prompt: String, source: String?, apiKey: String, automationMode: String = "AUTO_CREATE_PR") async throws -> Session {
        let url = URL(string: "\(baseURL)/sessions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        var body: [String: Any] = [
            "prompt": prompt,
            "automationMode": automationMode
        ]

        if let source = source {
            body["sourceContext"] = [
                "source": source,
                "githubRepoContext": ["startingBranch": "main"]
            ]
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? ""
            throw AIProviderError.networkError(errorBody)
        }

        return try JSONDecoder().decode(Session.self, from: data)
    }

    func getSession(id: String, apiKey: String) async throws -> Session {
        let url = URL(string: "\(baseURL)/sessions/\(id)")!
        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AIProviderError.invalidResponse
        }

        return try JSONDecoder().decode(Session.self, from: data)
    }

    func approvePlan(sessionID: String, apiKey: String) async throws {
        let url = URL(string: "\(baseURL)/sessions/\(sessionID):approvePlan")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw AIProviderError.invalidResponse
        }
    }
}
