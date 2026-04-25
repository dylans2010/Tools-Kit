import Foundation

/// Handles errors and provides user-friendly messages for Agent Mode.
final class AgentErrorHandler {
    static func handle(_ error: Error) -> String {
        if let agentError = error as? AgentError {
            return agentError.localizedDescription
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet:
                return "No internet connection. Please check your network."
            case NSURLErrorTimedOut:
                return "The request timed out. Please try again."
            default:
                return "A network error occurred: \(nsError.localizedDescription)"
            }
        }

        return "An unexpected error occurred: \(error.localizedDescription)"
    }
}
