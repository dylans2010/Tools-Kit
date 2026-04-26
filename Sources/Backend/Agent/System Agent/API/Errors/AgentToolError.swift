import Foundation

public enum AgentToolError: Error, LocalizedError {
    case toolNotFound(String)
    case executionFailed(String, Error)
    case invalidInput(String, String)

    public var errorDescription: String? {
        switch self {
        case .toolNotFound(let name): return "Tool not found: \(name)"
        case .executionFailed(let name, let e): return "Execution failed for tool '\(name)': \(e.localizedDescription)"
        case .invalidInput(let name, let reason): return "Invalid input for tool '\(name)': \(reason)"
        }
    }
}
