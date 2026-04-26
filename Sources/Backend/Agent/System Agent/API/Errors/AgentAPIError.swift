import Foundation

enum AgentAPIError: Error, LocalizedError {
    case invalidURL
    case unexpectedResponse
    case decodingError(Error)
    case serverError(Int, String)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL."
        case .unexpectedResponse: return "Received an unexpected response from the API."
        case .decodingError(let e): return "Failed to decode API response: \(e.localizedDescription)"
        case .serverError(let code, let msg): return "API Server Error (\(code)): \(msg)"
        case .unauthorized: return "Unauthorized API request."
        }
    }
}
