import Foundation

// MARK: - Agentic System Models

enum AgenticSystemState: String, Sendable {
    case idle
    case checkingAvailability
    case analyzingWorkspace
    case generatingTools
    case streaming
    case executingTool
    case completed
    case error
}

struct AgenticToolDefinition: Identifiable, Sendable {
    let id: String
    let name: String
    let description: String
    let sourceModule: String
    let parameters: [AgenticToolParameter]
    let derivedFrom: String
    let generatedAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        sourceModule: String,
        parameters: [AgenticToolParameter] = [],
        derivedFrom: String,
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.sourceModule = sourceModule
        self.parameters = parameters
        self.derivedFrom = derivedFrom
        self.generatedAt = generatedAt
    }
}

struct AgenticToolParameter: Sendable {
    let name: String
    let type: String
    let required: Bool
    let description: String
}

struct AgenticStreamToken: Identifiable, Sendable {
    let id: String
    let content: String
    let tokenType: TokenType
    let timestamp: Date

    init(content: String, tokenType: TokenType = .text) {
        self.id = UUID().uuidString
        self.content = content
        self.tokenType = tokenType
        self.timestamp = Date()
    }

    enum TokenType: String, Sendable {
        case text
        case reasoning
        case toolCall
        case toolResult
        case error
    }
}

struct AgenticExecutionStep: Identifiable, Sendable {
    let id: String
    let action: String
    let toolName: String?
    let input: String?
    let output: String?
    let status: StepStatus
    let startedAt: Date
    let completedAt: Date?

    init(
        id: String = UUID().uuidString,
        action: String,
        toolName: String? = nil,
        input: String? = nil,
        output: String? = nil,
        status: StepStatus = .running,
        startedAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.action = action
        self.toolName = toolName
        self.input = input
        self.output = output
        self.status = status
        self.startedAt = startedAt
        self.completedAt = completedAt
    }

    enum StepStatus: String, Sendable {
        case pending
        case running
        case completed
        case failed
    }
}

struct AgenticDiagnostic: Identifiable, Sendable {
    let id: String
    let level: DiagnosticLevel
    let message: String
    let timestamp: Date
    let component: String

    init(
        level: DiagnosticLevel,
        message: String,
        component: String
    ) {
        self.id = UUID().uuidString
        self.level = level
        self.message = message
        self.timestamp = Date()
        self.component = component
    }

    enum DiagnosticLevel: String, Sendable {
        case info
        case warning
        case error
        case success
    }
}

struct FoundationModelsStatus: Sendable {
    let isFrameworkAvailable: Bool
    let isRuntimeAvailable: Bool
    let isSessionReady: Bool
    let diagnosticMessage: String
    let checkedAt: Date

    init(
        isFrameworkAvailable: Bool,
        isRuntimeAvailable: Bool,
        isSessionReady: Bool,
        diagnosticMessage: String
    ) {
        self.isFrameworkAvailable = isFrameworkAvailable
        self.isRuntimeAvailable = isRuntimeAvailable
        self.isSessionReady = isSessionReady
        self.diagnosticMessage = diagnosticMessage
        self.checkedAt = Date()
    }

    var isFullyAvailable: Bool {
        isFrameworkAvailable && isRuntimeAvailable && isSessionReady
    }
}
