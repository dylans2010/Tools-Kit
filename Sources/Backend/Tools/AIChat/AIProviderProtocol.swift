import Foundation

// MARK: - AIModel

struct AIModel: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let supportsVision: Bool
    let contextLength: Int?

    init(id: String, name: String, supportsVision: Bool = false, contextLength: Int? = nil) {
        self.id = id
        self.name = name
        self.supportsVision = supportsVision
        self.contextLength = contextLength
    }
}

// MARK: - AIProvider Protocol

protocol AIProvider: Identifiable {
    var id: String { get }
    var name: String { get }
    var icon: String { get }
    var models: [AIModel] { get }
    var apiKeyURL: URL? { get }
    var apiKeyPlaceholder: String { get }

    func send(messages: [ChatMessage], model: String, apiKey: String) async throws -> String
    func sendWithAttachments(messages: [ChatMessage], attachments: [ChatAttachment], model: String, apiKey: String) async throws -> String
    func supportsVision(model: String) -> Bool
    func fetchModels(apiKey: String) async throws -> [AIModel]
    func validateAPIKey(_ key: String) async throws -> Bool
}

// MARK: - AIProviderError

enum AIProviderError: LocalizedError {
    case missingAPIKey
    case invalidAPIKey
    case networkError(String)
    case invalidResponse
    case unsupportedFeature(String)
    case providerMismatch(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:        return "No API key set for this provider."
        case .invalidAPIKey:        return "The API key is invalid or expired."
        case .networkError(let m): return "Network error: \(m)"
        case .invalidResponse:     return "Received an unexpected response from the provider."
        case .unsupportedFeature(let f): return "Unsupported feature: \(f)"
        case .providerMismatch(let m): return m
        }
    }
}
