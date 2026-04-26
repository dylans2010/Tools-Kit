import Foundation

enum SystemAgentError: Error, LocalizedError {
    case unknownTool(name: String)
    case aiServiceFailure(underlying: Error)
    case toolExecutionFailure(tool: String, underlying: Error)
    case emptyResponse
    case sessionReset
    case maxToolIterationsReached(limit: Int)

    var errorDescription: String? {
        switch self {
        case .unknownTool(let name):
            return "Unknown tool requested: \(name)"
        case .aiServiceFailure(let underlying):
            return "AI service failed: \(underlying.localizedDescription)"
        case .toolExecutionFailure(let tool, let underlying):
            return "Tool '\(tool)' failed: \(underlying.localizedDescription)"
        case .emptyResponse:
            return "The AI returned an empty response."
        case .sessionReset:
            return "The session was reset while processing your request."
        case .maxToolIterationsReached(let limit):
            return "Tool loop hit safety limit (\(limit) rounds)."
        }
    }
}
