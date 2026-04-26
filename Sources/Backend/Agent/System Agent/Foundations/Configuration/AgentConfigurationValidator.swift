import Foundation

struct AgentConfigurationValidator {
    enum ValidationError: Error, LocalizedError {
        case invalidTemperature(Double)
        case invalidMaxTokens(Int)
        case missingModelId

        var errorDescription: String? {
            switch self {
            case .invalidTemperature(let t): return "Temperature \(t) must be between 0 and 2."
            case .invalidMaxTokens(let m): return "Max tokens \(m) must be greater than 0."
            case .missingModelId: return "Model ID is required."
            }
        }
    }

    func validate(_ configuration: AgentConfiguration) throws {
        if configuration.modelId.isEmpty {
            throw ValidationError.missingModelId
        }
        if configuration.temperature < 0 || configuration.temperature > 2 {
            throw ValidationError.invalidTemperature(configuration.temperature)
        }
        if let maxTokens = configuration.maxTokens, maxTokens <= 0 {
            throw ValidationError.invalidMaxTokens(maxTokens)
        }
    }
}
