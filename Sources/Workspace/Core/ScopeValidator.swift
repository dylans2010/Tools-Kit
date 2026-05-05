import Foundation

final class ScopeValidator {
    static func validate(plugin: PluginDefinition, capability: PluginCapability) -> Bool {
        // High-risk scopes require API key and privacy note
        if capability.riskLevel == .high {
            guard let apiKey = plugin.apiKey, !apiKey.isEmpty,
                  let privacyNote = plugin.privacyNote, !privacyNote.isEmpty else {
                return false
            }
        }

        // External API scope check
        if (capability == .externalApiSendRequest || capability == .externalApiConnect) && plugin.endpoints.isEmpty {
            return false
        }

        // Connector scopes
        if capability == .connectorAuthManage && plugin.identifier.contains("connector") {
            // Additional checks for connectors can be added here
        }

        return true
    }
}
