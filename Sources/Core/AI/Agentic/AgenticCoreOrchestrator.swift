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

        logger.info("Starting orchestration loop for prompt: \(prompt)")

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

        logEvent(phase: "Availability Check", message: "Framework available: \(status.isFrameworkAvailable), Runtime: \(status.isRuntimeAvailable)", status: .completed)

        // Step 2: Analyze workspace
        state = .analyzingWorkspace
        logEvent(phase: "Workspace Analysis", message: "Scanning workspace directory structure", status: .started)

        do {
            let graph = try await analyzer.analyzeWorkspace()
            workspaceGraph = graph
            logEvent(
                phase: "Workspace Analysis",
                message: "Found \(graph.modules.count) modules, \(graph.totalFileCount) files, \(graph.featureDomains.count) domains",
                status: .completed
            )
        } catch {
            logEvent(phase: "Workspace Analysis", message: "Analysis failed: \(error.localizedDescription)", status: .failed)
            state = .error
            finalResponse = "Workspace analysis failed: \(error.localizedDescription)"
            return
        }

        // Step 3: Generate dynamic tools
        state = .generatingTools
        logEvent(phase: "Tool Generation", message: "Generating tools from workspace graph", status: .started)

        guard let graph = workspaceGraph else {
            logEvent(phase: "Tool Generation", message: "No workspace graph available", status: .failed)
            state = .error
            return
        }

        let tools = await toolRegistry.generateTools(from: graph)
        logEvent(phase: "Tool Generation", message: "Generated \(tools.count) dynamic tools", status: .completed)

        // Step 4: Build system context
        let systemContext = buildSystemContext(graph: graph, tools: tools)

        // Step 5: Stream AI response
        state = .streaming
        logEvent(phase: "AI Streaming", message: "Starting Foundation Models streaming session", status: .started)

        do {
            let response = try await sessionManager.streamResponse(
                prompt: prompt,
                systemContext: systemContext,
                tools: tools
            )

            logEvent(phase: "AI Streaming", message: "Stream completed with \(sessionManager.tokens.count) tokens", status: .completed)

            // Step 6: Parse and execute tool actions from response
            let toolActions = parseToolActions(from: response)

            if !toolActions.isEmpty {
                state = .executingTool
                logEvent(phase: "Tool Execution", message: "Executing \(toolActions.count) tool actions", status: .started)

                var toolOutputs: [String] = []
                for action in toolActions {
                    if let toolDef = toolRegistry.toolDefinition(named: action.toolName) {
                        let stepID = sessionManager.recordStep(
                            action: "Execute \(action.toolName)",
                            toolName: action.toolName,
                            input: action.parameters.description
                        )

                        do {
                            let output = try await toolExecutor.execute(tool: toolDef, parameters: action.parameters)
                            toolOutputs.append("\(action.toolName): \(output.summary)")
                            sessionManager.completeStep(id: stepID, output: output.summary, success: true)
                        } catch {
                            toolOutputs.append("\(action.toolName): Error - \(error.localizedDescription)")
                            sessionManager.completeStep(id: stepID, output: error.localizedDescription, success: false)
                        }
                    }
                }

                logEvent(phase: "Tool Execution", message: "Completed \(toolActions.count) tool actions", status: .completed)

                // Step 7: Feed tool outputs back if we have Foundation Models
                if status.isRuntimeAvailable && !toolOutputs.isEmpty {
                    let followUpPrompt = """
                    Tool execution results:
                    \(toolOutputs.joined(separator: "\n"))

                    Based on these results, provide a final summary for the user's original request: \(prompt)
                    """

                    do {
                        let followUp = try await sessionManager.streamResponse(
                            prompt: followUpPrompt,
                            systemContext: systemContext,
                            tools: tools
                        )
                        finalResponse = followUp
                    } catch {
                        finalResponse = response + "\n\nTool Results:\n" + toolOutputs.joined(separator: "\n")
                    }
                } else {
                    finalResponse = response + "\n\nTool Results:\n" + toolOutputs.joined(separator: "\n")
                }
            } else {
                finalResponse = response
            }

            state = .completed
            logEvent(phase: "Orchestration", message: "Orchestration loop complete", status: .completed)

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
        let capabilities = analyzer.detectExistingCapabilities(from: graph)
        let missing = analyzer.detectMissingCapabilities(from: graph)

        let moduleList = graph.modules.prefix(20).map { module in
            "  - \(module.name) [\(module.domain)]: \(module.files.count) files, \(module.declarations.count) declarations (\(module.capabilities.joined(separator: ", ")))"
        }.joined(separator: "\n")

        let toolList = tools.prefix(20).map { tool in
            "  - \(tool.name): \(tool.description)"
        }.joined(separator: "\n")

        return """
        You are an Agentic Runtime System operating within the Tools-Kit workspace.
        You have analyzed the actual project structure and generated tools dynamically.

        WORKSPACE ARCHITECTURE:
        Modules (\(graph.modules.count) total):
        \(moduleList)

        Feature Domains: \(graph.featureDomains.joined(separator: ", "))
        Relationships: \(graph.relationships.count) inter-module dependencies

        EXISTING CAPABILITIES:
        \(capabilities.map { "  - \($0.key): \($0.value.joined(separator: ", "))" }.joined(separator: "\n"))

        IDENTIFIED GAPS:
        \(missing.isEmpty ? "  None detected" : missing.map { "  - \($0)" }.joined(separator: "\n"))

        AVAILABLE TOOLS (\(tools.count)):
        \(toolList)

        RULES:
        - Only use tools that correspond to real workspace capabilities
        - Base all analysis on the actual scanned workspace data
        - Use streaming to emit reasoning and actions progressively
        - When executing tools, pass real parameters derived from workspace state
        - Report findings accurately based on real project structure
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
