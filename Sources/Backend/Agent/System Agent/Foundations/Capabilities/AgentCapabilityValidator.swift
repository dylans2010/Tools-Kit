import Foundation

struct AgentCapabilityValidator: Sendable {
    enum CapabilityError: Error, LocalizedError, Sendable {
        case missingCapability(String)

        var errorDescription: String? {
            switch self {
            case .missingCapability(let cap): return "Missing required capability: \(cap)"
            }
        }
    }

    init() {}

    func validate(capabilities: AgentCapabilities, required: [String]) throws {
        for req in required {
            switch req {
            case "tools":
                if !capabilities.canUseTools { throw CapabilityError.missingCapability(req) }
            case "vision":
                if !capabilities.canProcessVision { throw CapabilityError.missingCapability(req) }
            case "code":
                if !capabilities.canGenerateCode { throw CapabilityError.missingCapability(req) }
            case "internet":
                if !capabilities.canAccessInternet { throw CapabilityError.missingCapability(req) }
            default:
                break
            }
        }
    }
}
