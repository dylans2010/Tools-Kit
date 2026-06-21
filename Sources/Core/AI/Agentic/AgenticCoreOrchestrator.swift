import Foundation
import os

#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
final class AgenticCoreOrchestrator: ObservableObject {
    static let shared = AgenticCoreOrchestrator()

    @Published var state: AgenticSystemState = .idle
    @Published var workspaceGraph: WorkspaceGraph?
    @Published var availabilityStatus: FoundationModelsStatus?
    @Published var orchestrationLog: [OrchestrationEvent] = []
    @Published var currentPrompt: String = ""
    @Published var finalResponse: String = ""

    private let logger = Logger(subsystem: "com.toolskit.agentic", category: "orchestrator")
    private let availabilityChecker = AgenticFoundationModelsAvailabilityChecker.shared
    private let analyzer = AgenticWorkspaceAnalyzer.shared
    private let sessionManager = AgenticCoreSessionManager.shared
    private let toolRegistry = WorkspaceAITools.shared
    private let toolExecutor = AgenticToolExecutor.shared

    struct OrchestrationEvent: Identifiable {
        let id = UUID()
        let phase: String
        let message: String
        let timestamp: Date
        let status: EventStatus

        enum EventStatus: String {
            case started
            case completed
            case failed
            case skipped
        }
    }

    private init() {}

    // MARK: - Main Orchestration Loop

    func run(prompt: String) async {
        currentPrompt = prompt
        finalResponse = ""
        orchestrationLog = []

        logger.info("Starting foundation model chat session for prompt: \(prompt)")

        // Step 1: Check Foundation Models availability
        state = .checkingAvailability
        logEvent(phase: "Availability Check", message: "Checking Foundation Models availability", status: .started)

        let status = await availabilityChecker.checkFullAvailability()
        availabilityStatus = status

        guard status.isFrameworkAvailable else {
            logEvent(phase: "Availability Check", message: status.diagnosticMessage, status: .failed)
            state = .error
            finalResponse = "Foundation Models is not available: \(status.diagnosticMessage)"
            return
        }

        logEvent(phase: "Availability Check", message: "Framework available: \(status.isFrameworkAvailable)", status: .completed)

        // Step 2: Build system context
        let systemContext = buildSystemContext(graph: WorkspaceGraph(modules: [], featureDomains: [], relationships: []), tools: [])

        // Step 3: Stream AI response
        state = .streaming
        logEvent(phase: "AI Streaming", message: "Starting Foundation Models streaming session", status: .started)

        do {
            let response = try await sessionManager.streamResponse(
                prompt: prompt,
                systemContext: systemContext,
                tools: []
            )

            logEvent(phase: "AI Streaming", message: "Stream completed", status: .completed)
            finalResponse = response
            state = .completed
            logEvent(phase: "Chat", message: "Response received successfully", status: .completed)

        } catch {
            logEvent(phase: "AI Streaming", message: "Streaming failed: \(error.localizedDescription)", status: .failed)

            // Fallback: execute tools based on workspace analysis without streaming
            state = .executingTool
            let fallbackResponse = await executeFallbackLoop(prompt: prompt, graph: graph, tools: tools)
            finalResponse = fallbackResponse
            state = .completed
            logEvent(phase: "Orchestration", message: "Completed with fallback execution", status: .completed)
        }
    }

    // MARK: - System Context

    private func buildSystemContext(graph: WorkspaceGraph, tools: [AgenticToolDefinition]) -> String {
        var baseInstructions = ""
        if let url = Bundle.main.url(forResource: "FoundationModelsSystem", withExtension: "md"),
           let content = try? String(contentsOf: url) {
            baseInstructions = content
        } else {
            baseInstructions = "You are a helpful AI assistant powered by Foundation Models."
        }

        let skillsPrompt = AIService.SkillsManager.shared.activeSkillsPrompt()

        return """
        \(baseInstructions)

        \(skillsPrompt)

        You are currently in a workspace-aware chat session. While you can answer questions about the environment, your primary role is a helpful conversationalist.
        """
    }

    // MARK: - Tool Action Parsing

    struct ToolAction {
        let toolName: String
        let parameters: [String: String]
    }

    private func parseToolActions(from response: String) -> [ToolAction] {
        var actions: [ToolAction] = []
        let lines = response.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("TOOL:") || trimmed.hasPrefix("tool:") || trimmed.hasPrefix("ACTION:") || trimmed.hasPrefix("action:") {
                let afterPrefix = trimmed.components(separatedBy: ":").dropFirst().joined(separator: ":")
                    .trimmingCharacters(in: .whitespaces)

                let parts = afterPrefix.components(separatedBy: "(")
                guard let toolName = parts.first?.trimmingCharacters(in: .whitespaces), !toolName.isEmpty else { continue }

                var params: [String: String] = [:]
                if parts.count > 1 {
                    let paramStr = parts[1].replacingOccurrences(of: ")", with: "")
                    let paramParts = paramStr.components(separatedBy: ",")
                    for part in paramParts {
                        let kv = part.components(separatedBy: "=")
                        if kv.count == 2 {
                            params[kv[0].trimmingCharacters(in: .whitespaces)] = kv[1].trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                        }
                    }
                }

                if toolRegistry.toolDefinition(named: toolName) != nil {
                    actions.append(ToolAction(toolName: toolName, parameters: params))
                }
            }
        }

        return actions
    }

    // MARK: - Fallback Execution

    private func executeFallbackLoop(prompt: String, graph: WorkspaceGraph, tools: [AgenticToolDefinition]) async -> String {
        sessionManager.addDiagnostic(
            level: .warning,
            message: "Using fallback execution (Foundation Models streaming unavailable)",
            component: "Orchestrator"
        )

        var response = "Workspace Analysis Results for: \(prompt)\n\n"

        response += "Architecture Overview:\n"
        response += "- \(graph.modules.count) modules across \(graph.featureDomains.count) domains\n"
        response += "- \(graph.totalFileCount) total source files\n"
        response += "- \(graph.relationships.count) inter-module relationships\n\n"

        response += "Feature Domains: \(graph.featureDomains.joined(separator: ", "))\n\n"

        let capabilities = analyzer.detectExistingCapabilities(from: graph)
        response += "Capabilities by Domain:\n"
        for (domain, caps) in capabilities.sorted(by: { $0.key < $1.key }) {
            response += "  \(domain): \(caps.joined(separator: ", "))\n"
        }

        let missing = analyzer.detectMissingCapabilities(from: graph)
        if !missing.isEmpty {
            response += "\nIdentified Gaps:\n"
            for gap in missing {
                response += "  - \(gap)\n"
            }
        }

        response += "\nAvailable Tools (\(tools.count)):\n"
        for tool in tools.prefix(10) {
            response += "  - \(tool.name): \(tool.description)\n"
        }

        return response
    }

    // MARK: - Utilities

    func reset() {
        state = .idle
        workspaceGraph = nil
        availabilityStatus = nil
        orchestrationLog = []
        currentPrompt = ""
        finalResponse = ""
        sessionManager.clearSession()
        analyzer.invalidateCache()
    }

    private func logEvent(phase: String, message: String, status: OrchestrationEvent.EventStatus) {
        let event = OrchestrationEvent(phase: phase, message: message, timestamp: Date(), status: status)
        orchestrationLog.append(event)
        logger.info("[\(phase)] \(status.rawValue): \(message)")
    }
}
