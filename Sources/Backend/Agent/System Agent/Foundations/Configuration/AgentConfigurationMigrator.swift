import Foundation

struct AgentConfigurationMigrator {
    func migrateLegacy(_ dictionary: [String: Any]) -> AgentConfiguration {
        AgentConfiguration(
            toolExecutionTimeout: dictionary["toolExecutionTimeout"] as? TimeInterval ?? AgentConfiguration.default.toolExecutionTimeout,
            maxToolIterations: dictionary["maxToolIterations"] as? Int ?? AgentConfiguration.default.maxToolIterations,
            streamingEnabled: dictionary["streamingEnabled"] as? Bool ?? AgentConfiguration.default.streamingEnabled
        )
    }
}
