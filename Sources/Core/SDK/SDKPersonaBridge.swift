import Foundation
import Combine

@MainActor
public final class SDKPersonaBridge: ObservableObject {
    public static let shared = SDKPersonaBridge()

    @Published public var queryHistory: [PersonaQueryRecord] = []

    private let maxHistorySize = 200
    private let persistenceURL: URL
    private let queue = DispatchQueue(label: "com.toolskit.sdk.persona", qos: .utility)

    public struct PersonaQueryRecord: Identifiable, Codable {
        public let id: UUID
        public let prompt: String
        public let response: String
        public let timestamp: Date
        public let queryType: QueryType

        public enum QueryType: String, Codable {
            case query, generate, analyze, summarize, memoryWrite
        }
    }

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        persistenceURL = appSupport.appendingPathComponent("sdk_persona_history.json")

        if !FileManager.default.fileExists(atPath: appSupport.path) {
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }

        loadHistory()
    }

    // MARK: - Query Persona

    public func queryPersona(prompt: String) async throws -> String {
        SDKLogStore.shared.log("Persona query: \(prompt.prefix(50))...", source: "SDKPersonaBridge", level: .info)

        let response = try await WorkspaceAPI.shared.persona.queryPersona(prompt: prompt)
        recordQuery(prompt: prompt, response: response, type: .query)
        return response
    }

    // MARK: - Generate

    public func generate(prompt: String, context: [String: Any]) async throws -> String {
        let contextString = context.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        let fullPrompt = contextString.isEmpty ? prompt : "Context:\n\(contextString)\n\nPrompt: \(prompt)"

        let response = try await WorkspaceAPI.shared.persona.queryPersona(prompt: fullPrompt)
        recordQuery(prompt: prompt, response: response, type: .generate)
        return response
    }

    // MARK: - Analyze

    public func analyze(data: [SDKDataItem], prompt: String) async throws -> String {
        let dataSummary = data.prefix(20).map { "[\($0.scope)] \($0.title)" }.joined(separator: "\n")
        let fullPrompt = "Analyze the following data:\n\(dataSummary)\n\nAnalysis request: \(prompt)"

        let response = try await WorkspaceAPI.shared.persona.queryPersona(prompt: fullPrompt)
        recordQuery(prompt: prompt, response: response, type: .analyze)
        return response
    }

    // MARK: - Summarize

    public func summarize(items: [SDKDataItem]) async throws -> String {
        let itemDescriptions = items.prefix(30).map { "[\($0.scope)] \($0.title): \($0.codablePayload.values.joined(separator: ", "))" }.joined(separator: "\n")
        let prompt = "Summarize the following workspace items:\n\(itemDescriptions)"

        let response = try await WorkspaceAPI.shared.persona.queryPersona(prompt: prompt)
        recordQuery(prompt: "summarize \(items.count) items", response: response, type: .summarize)
        return response
    }

    // MARK: - Write Memory

    public func writeMemory(entityID: UUID, memory: String) async throws {
        WorkspaceAPI.shared.persona.injectMemory(content: "[\(entityID)] \(memory)")
        recordQuery(prompt: "Memory write for \(entityID)", response: "Written", type: .memoryWrite)

        let action = SDKAction.injectMemory(entityID: entityID, memory: memory)
        let context = SDKExecutionContext(projectID: UUID(), noSandbox: SDKRuntimeEngine.shared.isNoSandboxModeEnabled)
        try await SDKExecutionKernel.shared.execute(action: action, context: context)

        SDKLogStore.shared.log("Persona memory written for entity \(entityID)", source: "SDKPersonaBridge", level: .info)
    }

    // MARK: - Private

    private func recordQuery(prompt: String, response: String, type: PersonaQueryRecord.QueryType) {
        let record = PersonaQueryRecord(
            id: UUID(),
            prompt: prompt,
            response: response,
            timestamp: Date(),
            queryType: type
        )
        queryHistory.insert(record, at: 0)
        if queryHistory.count > maxHistorySize {
            queryHistory = Array(queryHistory.prefix(maxHistorySize))
        }
        persistHistory()
    }

    private func persistHistory() {
        let history = queryHistory
        queue.async { [weak self] in
            guard let url = self?.persistenceURL else { return }
            if let data = try? JSONEncoder().encode(history) {
                try? data.write(to: url)
            }
        }
    }

    private func loadHistory() {
        guard let data = try? Data(contentsOf: persistenceURL),
              let decoded = try? JSONDecoder().decode([PersonaQueryRecord].self, from: data) else { return }
        queryHistory = decoded
    }
}
