import Foundation

public enum AgentValidationError: Error, LocalizedError {
    case missingRequiredField(String)
    case invalidFormat(String)

    public var errorDescription: String? {
        switch self {
        case .missingRequiredField(let field): return "Missing required field: \(field)"
        case .invalidFormat(let field): return "Invalid format for field: \(field)"
        }
    }
}
