import Foundation

@MainActor
final class AgenticCoreOrchestrator: ObservableObject {
    static let shared = AgenticCoreOrchestrator()

    @Published var isProcessing = false
    @Published var lastMessage = ""
    @Published var streamingTokens = ""
    @Published var deviceCapability: AgenticDeviceCapability?

    private let sessionManager = AgenticCoreSessionManager.shared
    private let toolExecutor = AgenticToolExecutor.shared
    private let traceStore = AgenticExecutionTraceStore.shared
    private let capabilityChecker = AgenticCoreDeviceCapabilityChecker.shared
    private let integrityLayer = AgenticIntegrityValidationLayer.shared

    private init() {
        self.deviceCapability = capabilityChecker.checkCapability()
    }

    func processRequest(_ prompt: String) async {
        guard deviceCapability?.isSupported == true else {
            lastMessage = "Agentic features are unavailable: \(deviceCapability?.reason ?? "Unknown error")"
            return
        }

        isProcessing = true
        streamingTokens = ""
        var history: [AgenticModelResponse] = []

        do {
            // 1. Start streaming session
            let stream = try await sessionManager.streamOrchestrationResponse(prompt: prompt, history: history)

            for try await token in stream {
                streamingTokens += token
                // Optional: partial parsing for tool call detection during stream
            }

            // 2. Final parse and validation
            let response = sessionManager.parseResponse(streamingTokens)
            try integrityLayer.validateModelReasoning(response.message)

            history.append(response)
            lastMessage = response.message

            // 3. Execute tools
            for action in response.actions {
                let trace = AgenticExecutionTrace(toolName: action.toolName, parameters: action.parameters)
                traceStore.addTrace(trace)

                traceStore.updateTrace(id: trace.id, status: .running)

                do {
                    let output = try await toolExecutor.execute(toolName: action.toolName, parameters: action.parameters)

                    // Validate Integrity (Zero Tolerance for mocks)
                    try integrityLayer.validateToolOutput(output, from: action.toolName)

                    traceStore.updateTrace(id: trace.id, status: .completed, output: output)

                } catch {
                    traceStore.updateTrace(id: trace.id, status: .failed, error: error.localizedDescription)
                    break
                }
            }

        } catch {
            print("[Agentic] Orchestration error: \(error.localizedDescription)")
            lastMessage = "Error: \(error.localizedDescription)"
        }

        isProcessing = false
    }
}
