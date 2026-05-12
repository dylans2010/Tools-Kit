import Foundation

@MainActor
final class AgenticCoreOrchestrator: ObservableObject {
    static let shared = AgenticCoreOrchestrator()

    @Published var isProcessing = false
    @Published var lastMessage = ""

    private let sessionManager = AgenticCoreSessionManager.shared
    private let toolExecutor = AgenticToolExecutor.shared
    private let traceStore = AgenticExecutionTraceStore.shared

    private init() {}

    func processRequest(_ prompt: String) async {
        isProcessing = true
        var history: [AgenticModelResponse] = []
        var isComplete = false

        do {
            while !isComplete {
                // 1. Model emits actions
                let response = try await sessionManager.getOrchestrationResponse(prompt: prompt, history: history)
                history.append(response)
                lastMessage = response.message

                if response.actions.isEmpty && response.isComplete {
                    isComplete = true
                    break
                }

                // 2. Execute tools
                for action in response.actions {
                    let trace = AgenticExecutionTrace(toolName: action.toolName, parameters: action.parameters)
                    traceStore.addTrace(trace)

                    // UI: Preparing -> Running
                    traceStore.updateTrace(id: trace.id, status: .running)

                    do {
                        let output = try await toolExecutor.execute(toolName: action.toolName, parameters: action.parameters)

                        // UI: Running -> Completed
                        traceStore.updateTrace(id: trace.id, status: .completed, output: output)

                        // If code exists -> simulate writing .swift file
                        if let code = output.generatedCode {
                            print("[Agentic] Writing generated code for \(action.toolName)")
                            // In real app: try code.write(to: ...)
                        }

                    } catch {
                        traceStore.updateTrace(id: trace.id, status: .failed, error: error.localizedDescription)
                        isComplete = true
                        break
                    }
                }

                if response.isComplete {
                    isComplete = true
                }
            }
        } catch {
            print("[Agentic] Orchestration error: \(error.localizedDescription)")
            lastMessage = "Error: \(error.localizedDescription)"
        }

        isProcessing = false
    }
}
