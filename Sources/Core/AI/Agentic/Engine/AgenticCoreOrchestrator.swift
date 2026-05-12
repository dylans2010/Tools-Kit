import Foundation
import FoundationModels
import SwiftUI

@MainActor
final class AgenticCoreOrchestrator: ObservableObject {
    static let shared = AgenticCoreOrchestrator()

    @Published var executionState: AgenticExecutionState = .idle
    @Published var streamedText: String = ""
    @Published var currentActions: [AgenticModelAction] = []
    @Published var toolOutputs: [String: AgenticToolOutput] = [:]
    @Published var iterationCount: Int = 0

    private let capabilityService = AgenticCoreDeviceCapabilityService.shared
    private let sessionManager = AgenticCoreSessionManager.shared
    private let toolExecutor = AgenticToolExecutor.shared
    private let registry = WorkspaceAITools.shared
    private let traceStore = AgenticExecutionTraceStore.shared

    var config = AgenticSessionConfig()

    private init() {}

    // MARK: - Main Execution Loop

    func execute(prompt: String) async throws -> AgenticModelResponse {
        // Step 1: Validate device capability
        let capability = capabilityService.evaluate()
        guard capability.isSupported else {
            let reason = capability.requiredReason ?? "Device not supported"
            traceStore.record(phase: "capability_check", detail: "BLOCKED: \(reason)")
            throw AgenticSessionError.deviceNotSupported(reason)
        }
        traceStore.record(phase: "capability_check", detail: "Device supported: \(capability.deviceClass)")

        // Step 2: Load registry context
        executionState = .preparing
        let toolContext = registry.registryContextForModel()
        traceStore.record(phase: "registry_load", detail: "Loaded \(registry.tools.count) tools into context")

        // Step 3: Build system instructions with tool registry
        let workspaceData = PersonaWorkspace.gatherFullWorkspaceData()
        let systemInstructions = buildSystemInstructions(toolContext: toolContext, workspaceData: workspaceData)

        // Step 4: Create streaming session
        sessionManager.createSession(instructions: systemInstructions)

        // Step 5: Begin streaming execution loop
        iterationCount = 0
        toolOutputs.removeAll()
        currentActions.removeAll()
        streamedText = ""

        var lastResponse: AgenticModelResponse?
        var currentPrompt = prompt

        repeat {
            iterationCount += 1
            traceStore.record(phase: "iteration", detail: "Starting iteration \(iterationCount)")

            // Step 6: Stream model response
            executionState = .streaming
            let response = try await sessionManager.streamResponse(prompt: currentPrompt)
            lastResponse = response
            streamedText = response.message
            currentActions = response.actions

            // Step 7: Validate and execute tool actions
            if !response.actions.isEmpty {
                executionState = .executingTool
                var toolResults: [String] = []

                for action in response.actions {
                    if !registry.validate(toolName: action.toolName) {
                        traceStore.record(phase: "tool_validation", detail: "Rejected unknown tool: \(action.toolName)")
                        toolResults.append("ERROR: Tool '\(action.toolName)' is not registered.")
                        continue
                    }

                    do {
                        let output = try await toolExecutor.execute(action: action)
                        toolOutputs[action.toolName] = output
                        toolResults.append("[\(action.toolName)] Result: \(output.summary)")
                    } catch {
                        traceStore.markError(error, context: "Tool execution: \(action.toolName)")
                        toolResults.append("[\(action.toolName)] ERROR: \(error.localizedDescription)")
                    }
                }

                // Step 8: Inject tool results back into model context
                if !response.isComplete {
                    currentPrompt = """
                    Tool execution results:
                    \(toolResults.joined(separator: "\n"))

                    Continue with the remaining work based on these results.
                    """
                }
            }

            guard iterationCount < config.maxIterations else {
                traceStore.record(phase: "iteration", detail: "Max iterations reached (\(config.maxIterations))")
                break
            }

        } while lastResponse?.isComplete == false

        // Step 9: Finalize
        executionState = .completed
        traceStore.record(phase: "complete", detail: "Execution finished after \(iterationCount) iteration(s)")

        return lastResponse ?? AgenticModelResponse(
            message: streamedText,
            actions: [],
            isComplete: true,
            confidenceScore: 1.0
        )
    }

    // MARK: - Interruption

    func interrupt() {
        sessionManager.interrupt()
        executionState = .interrupted
        traceStore.record(phase: "interruption", detail: "Orchestrator interrupted by user")
    }

    func reset() {
        sessionManager.resetSession()
        executionState = .idle
        streamedText = ""
        currentActions.removeAll()
        toolOutputs.removeAll()
        iterationCount = 0
        traceStore.clear()
    }

    // MARK: - System Instructions Builder

    private func buildSystemInstructions(toolContext: String, workspaceData: String) -> String {
        return """
        You are an Agentic AI execution kernel embedded in a personal workspace application.
        You convert natural language into structured operations and tool executions.

        EXECUTION PROTOCOL:
        1. Analyze the user request against available workspace data.
        2. Determine which tools to invoke from the registry below.
        3. Emit structured AgenticModelAction items with exact tool names and parameters.
        4. Wait for tool execution results before continuing if needed.
        5. Set isComplete=true only when the full request is satisfied.
        6. Never hallucinate tools or parameters not in the registry.
        7. Provide reasoning in your message field.

        \(toolContext)

        WORKSPACE STATE:
        \(workspaceData)

        OUTPUT FORMAT:
        Respond as AgenticModelResponse with:
        - message: Your reasoning and response to the user
        - actions: Array of AgenticModelAction with toolName, parameters, expectedOutcome
        - isComplete: Whether this request is fully resolved
        - confidenceScore: 0.0 to 1.0 confidence in your response
        """
    }
}
