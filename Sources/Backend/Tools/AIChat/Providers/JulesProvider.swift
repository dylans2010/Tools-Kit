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

    private let requestManager: JulesRequestManager

    init(requestManager: JulesRequestManager = .shared) {
        self.requestManager = requestManager
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

    struct Source: Codable, Identifiable, Sendable {
        let name: String
        let id: String
        let githubRepo: GitHubRepo?

        struct GitHubRepo: Codable, Sendable {
            let owner: String
            let repo: String
        }
    }

    struct Session: Codable, Identifiable, Sendable {
        let name: String
        let id: String
        let title: String?
        let prompt: String
        let outputs: [Output]?

        struct Output: Codable, Sendable { let pullRequest: PullRequest? }
        struct PullRequest: Codable, Sendable { let url: String; let title: String; let description: String }
    }

    private struct SourceListResponse: Codable, Sendable { let sources: [Source] }

    private struct CreateSessionRequest: Encodable, JulesPayloadValidating, Sendable {
        let prompt: String
        let sourceContext: SourceContext?
        let automationMode: String

        struct SourceContext: Encodable, Sendable {
            let source: String
            let githubRepoContext: GitHubRepoContext

            struct GitHubRepoContext: Encodable, Sendable {
                let startingBranch: String
            }
        }

        func validationErrors() -> [JulesRequestManager.FieldValidationError] {
            var errors: [JulesRequestManager.FieldValidationError] = []
            if prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append(.init(field: "prompt", reason: "prompt must be non-empty"))
            }
            if let sourceContext, sourceContext.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append(.init(field: "sourceContext.source", reason: "sourceContext.source must be non-empty"))
            }
            if !["AUTO_CREATE_PR", "NO_AUTOMATION"].contains(automationMode) {
                errors.append(.init(field: "automationMode", reason: "unsupported value \(automationMode)"))
            }
            return errors
        }
    }

    func listSources(apiKey: String) async throws -> [Source] {
        do {
            let response: SourceListResponse = try await requestManager.send(path: "sources", apiKeyOverride: apiKey)
            return response.sources
        } catch {
            throw AIProviderError.networkError(error.localizedDescription)
        }
    }

    func createSession(prompt: String, source: String?, apiKey: String, automationMode: String = "AUTO_CREATE_PR") async throws -> Session {
        let body = CreateSessionRequest(
            prompt: prompt.trimmingCharacters(in: .whitespacesAndNewlines),
            sourceContext: source.map {
                .init(source: $0.trimmingCharacters(in: .whitespacesAndNewlines), githubRepoContext: .init(startingBranch: "main"))
            },
            automationMode: automationMode
        )

        do {
            let session: Session = try await requestManager.send(path: "sessions", method: "POST", body: body, apiKeyOverride: apiKey)
            return session
        } catch {
            throw AIProviderError.networkError(error.localizedDescription)
        }
    }

    func getSession(id: String, apiKey: String) async throws -> Session {
        do {
            let session: Session = try await requestManager.send(path: "sessions/\(id)", apiKeyOverride: apiKey)
            return session
        } catch {
            throw AIProviderError.networkError(error.localizedDescription)
        }
    }

    func approvePlan(sessionID: String, apiKey: String) async throws {
        do {
            try await requestManager.sendVoid(path: "sessions/\(sessionID):approvePlan", method: "POST", body: JulesNoBody(), apiKeyOverride: apiKey)
        } catch {
            throw AIProviderError.networkError(error.localizedDescription)
        }
    }
}
