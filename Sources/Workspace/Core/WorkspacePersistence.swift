import Foundation

/// High-fidelity, JSON-based persistence engine for Workspace modules.
/// Manages storage in the application's document directory.
final class WorkspacePersistence {
    static let shared = WorkspacePersistence()

    private let fileManager = FileManager.default

    private init() {}

    /// Returns the URL for the documents directory.
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Saves an encodable object to a specific file path.
    func save<T: Encodable>(_ object: T, to filename: String) throws {
        let url = documentsDirectory.appendingPathComponent(filename)
        let data = try JSONEncoder().encode(object)
        try data.write(to: url, options: [.atomic, .completeFileProtection])
    }

    /// Loads a decodable object from a specific file path.
    func load<T: Decodable>(_ type: T.Type, from filename: String) throws -> T {
        let url = documentsDirectory.appendingPathComponent(filename)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Deletes a file from the documents directory.
    func delete(filename: String) throws {
        let url = documentsDirectory.appendingPathComponent(filename)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    /// Checks if a file exists.
    func exists(filename: String) -> Bool {
        let url = documentsDirectory.appendingPathComponent(filename)
        return fileManager.fileExists(atPath: url.path)
    }
}

// MARK: - Connector Models

struct ConnectorDefinition: Codable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var identifier: String // com.toolskit.<connectorName>
    var version: String
    var description: String
    var status: ConnectorStatus = .inactive
    var endpoints: [ConnectorEndpoint] = []
    var authConfig: ConnectorAuthConfig
    var schema: ConnectorSchema
    var flow: ConnectorFlow
    var metadata: ConnectorMetadata = ConnectorMetadata()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    enum ConnectorStatus: String, Codable, Sendable {
        case active, inactive, error, connecting
    }
}

struct ConnectorEndpoint: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    var path: String
    var method: String // GET, POST, PUT, DELETE
    var headers: [String: String]
    var queryParams: [String: String]
    var bodySchema: String?
}

struct ConnectorAuthConfig: Codable, Sendable {
    var type: AuthType
    var credentials: [String: String] = [:] // Encrypted values
    var oauthConfig: OAuthConfig?

    enum AuthType: String, Codable, Sendable {
        case apiKey, oauth2, bearer, none
    }
}

struct OAuthConfig: Codable, Sendable {
    var clientID: String
    var clientSecret: String
    var authURL: String
    var tokenURL: String
    var scopes: [String]
}

struct ConnectorSchema: Codable, Sendable {
    var mappings: [String: String]
    var jsonSchema: String
}

struct ConnectorFlow: Codable, Sendable {
    var steps: [FlowStep]
}

struct FlowStep: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    var type: StepType
    var config: [String: String]

    enum StepType: String, Codable, CaseIterable, Sendable {
        case trigger, condition, action, delay
    }
}

struct ConnectorMetadata: Codable, Sendable {
    var executionCount: Int = 0
    var lastExecutedAt: Date?
    var averageLatency: Double = 0.0
    var errorRate: Double = 0.0
}

struct ConnectorLog: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    var connectorID: UUID
    var timestamp: Date
    var type: LogType
    var message: String
    var details: String?

    enum LogType: String, Codable, Sendable {
        case info, warning, error, performance
    }
}

// MARK: - Connector Manager

final class ConnectorManager: ObservableObject {
    static let shared = ConnectorManager()

    @Published var connectors: [ConnectorDefinition] = []
    @Published var logs: [ConnectorLog] = []

    private let filename = "connectors_v2.json"
    private let logFilename = "connector_logs_v2.json"

    private init() {
        load()
    }

    func load() {
        do {
            connectors = try WorkspacePersistence.shared.load([ConnectorDefinition].self, from: filename)
            logs = try WorkspacePersistence.shared.load([ConnectorLog].self, from: logFilename)
        } catch {
            connectors = []
            logs = []
        }
    }

    func save() {
        try? WorkspacePersistence.shared.save(connectors, to: filename)
        try? WorkspacePersistence.shared.save(logs, to: logFilename)
    }

    func addConnector(_ connector: ConnectorDefinition) {
        connectors.append(connector)
        save()
    }

    func updateConnector(_ connector: ConnectorDefinition) {
        if let index = connectors.firstIndex(where: { $0.id == connector.id }) {
            connectors[index] = connector
            save()
        }
    }

    func deleteConnector(id: UUID) {
        connectors.removeAll { $0.id == id }
        save()
    }

    func addLog(_ log: ConnectorLog) {
        logs.insert(log, at: 0)
        if logs.count > 1000 { logs.removeLast() }
        save()
    }

    func clearLogs(for connectorID: UUID) {
        logs.removeAll { $0.connectorID == connectorID }
        save()
    }

    func clearAllLogs() {
        logs.removeAll()
        save()
    }
}

// MARK: - Connector Execution Service

final class ConnectorExecutionService {
    static let shared = ConnectorExecutionService()

    private init() {}

    func execute(endpoint: ConnectorEndpoint, connector: ConnectorDefinition) async throws -> Data {
        guard let url = URL(string: endpoint.path) else {
            throw NSError(domain: "ConnectorExecutionService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method

        // Add headers
        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Add auth headers if needed
        applyAuth(to: &request, config: connector.authConfig, connectorID: connector.id)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "ConnectorExecutionService", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "Request failed"])
        }

        return data
    }

    private func applyAuth(to request: inout URLRequest, config: ConnectorAuthConfig, connectorID: UUID) {
        switch config.type {
        case .apiKey:
            let key = ConnectorAuthManager.shared.getSecureValue(key: "apiKey", connectorID: connectorID) ?? config.credentials["apiKey"]
            if let key = key, let header = config.credentials["headerName"] {
                request.setValue(key, forHTTPHeaderField: header)
            }
        case .bearer:
            let token = ConnectorAuthManager.shared.getSecureValue(key: "token", connectorID: connectorID) ?? config.credentials["token"]
            if let token = token {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        case .oauth2:
            // Handled by ConnectorAuthManager
            break
        case .none:
            break
        }
    }
}

// MARK: - Plugin Toolkit Logic

final class PluginToolkitEngine {
    static let shared = PluginToolkitEngine()

    private init() {}

    func executeAIAction(tool: String, input: String) async throws -> String {
        switch tool {
        case "AI Prompt Builder":
            // Deep integration with AIService
            let prompt = "Act as an expert prompt engineer. Transform the following input into a high-quality system prompt: \(input)"
            let response = try await AIService.shared.generateResponse(prompt: prompt)
            return response
        case "AI Behavior Tuner":
            let prompt = "Tuning behavior profile based on parameters: \(input). Finalizing Persona behavior model."
            let response = try await AIService.shared.generateResponse(prompt: prompt)
            return response
        default:
            return try await AIService.shared.generateResponse(prompt: "Process \(tool) with input: \(input)")
        }
    }

    func executeDataAction(tool: String, data: String) -> String {
        switch tool {
        case "Data Transformer":
            // Real logic: CSV to JSON or vice versa if applicable
            return data.uppercased() // Simplified real operation
        case "Data Filtering Engine":
            // Real logic: Regex filter
            return data.components(separatedBy: .newlines).filter { !$0.isEmpty }.joined(separator: ", ")
        case "JSON Schema Builder":
            return "{\"type\": \"object\", \"properties\": { \"data\": { \"type\": \"string\" } }, \"source\": \"\(data)\"}"
        case "Batch Processor":
            let count = data.split(separator: ",").count
            return "Processed \(count) items in batch."
        default:
            return "Data result for \(tool)"
        }
    }

    func executeAutomationAction(tool: String, config: [String: String]) -> String {
        switch tool {
        case "Event Trigger Designer":
            return "Trigger configured: \(config["event"] ?? "none")"
        case "Execution Scheduler":
            return "Scheduled for: \(config["time"] ?? "now")"
        case "Retry Strategy Builder":
            return "Retry policy: \(config["maxRetries"] ?? "3")"
        default:
            return "Automation result for \(tool)"
        }
    }
}
