import Foundation
import FoundationModels

// MARK: - Core Generable Types

@Generable
struct AgenticModelResponse {
    var message: String
    var actions: [AgenticModelAction]
    var isComplete: Bool
    var confidenceScore: Double
}

@Generable
struct AgenticModelAction {
    var toolName: String
    var parameters: [String: String]
    var expectedOutcome: String
}

@Generable
struct AgenticToolOutput {
    var summary: String
    var generatedCode: String?
    var metadata: [String: String]
    var dataPayload: [String: String]
}

@Generable
struct AgenticDeviceCapability {
    let isSupported: Bool
    let requiredReason: String?
    let deviceClass: String
}

// MARK: - Execution State

enum AgenticExecutionState: String, Sendable {
    case idle
    case preparing
    case streaming
    case executingTool
    case completed
    case failed
    case interrupted
}

// MARK: - Tool Definition

struct WorkspaceAIToolDefinition: Identifiable, Sendable {
    let id: String
    let name: String
    let description: String
    let category: String
    let inputSchema: [String: String]
    let producesCode: Bool
    let deterministic: Bool

    init(name: String, description: String, category: String, inputSchema: [String: String], producesCode: Bool = false, deterministic: Bool = true) {
        self.id = name
        self.name = name
        self.description = description
        self.category = category
        self.inputSchema = inputSchema
        self.producesCode = producesCode
        self.deterministic = deterministic
    }
}

// MARK: - Trace Entry

struct AgenticTraceEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let phase: String
    let detail: String
    let toolName: String?
    let inputSnapshot: [String: String]?
    let outputSnapshot: [String: String]?
    let durationMs: Double?

    init(phase: String, detail: String, toolName: String? = nil, inputSnapshot: [String: String]? = nil, outputSnapshot: [String: String]? = nil, durationMs: Double? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.phase = phase
        self.detail = detail
        self.toolName = toolName
        self.inputSnapshot = inputSnapshot
        self.outputSnapshot = outputSnapshot
        self.durationMs = durationMs
    }
}

// MARK: - Streaming Token

struct AgenticStreamToken: Identifiable {
    let id: UUID = UUID()
    let content: String
    let timestamp: Date = Date()
    let isReasoning: Bool
}

// MARK: - Session Configuration

struct AgenticSessionConfig {
    var maxIterations: Int = 10
    var streamingEnabled: Bool = true
    var traceEnabled: Bool = true
    var timeoutSeconds: TimeInterval = 60
}
