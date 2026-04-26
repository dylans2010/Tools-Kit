import Foundation

struct AgentConfigurationValidator {
    func validate(_ configuration: AgentConfiguration) -> [String] {
        var errors: [String] = []
        if configuration.toolExecutionTimeout <= 0 { errors.append("toolExecutionTimeout must be positive") }
        if configuration.maxToolIterations <= 0 { errors.append("maxToolIterations must be positive") }
        return errors
    }
}
