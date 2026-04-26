import Foundation

enum AgentNetworkError: Error, LocalizedError {
    case noConnection
    case timeout
    case cancelled
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .noConnection: return "No internet connection."
        case .timeout: return "The request timed out."
        case .cancelled: return "The request was cancelled."
        case .underlying(let e): return e.localizedDescription
        }
    }
}
