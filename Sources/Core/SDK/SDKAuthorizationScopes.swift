import Foundation

public extension SDKModuleDescriptor {
    var requiredScopes: [String] {
        let mapped = capabilities.flatMap(\.requiredScopes)
        return Array(Set(mapped)).sorted()
    }
}

public extension SDKModuleCapability {
    var requiredScopes: [String] {
        switch self {
        case .storage:
            return ["workspace.files.read", "workspace.files.write"]
        case .networking:
            return ["external.api.unrestricted"]
        case .rendering:
            return ["workspace.files.read"]
        case .automation:
            return ["workspace.automation.execute"]
        case .authentication:
            return ["workspace.runtime.admin"]
        case .analytics:
            return ["workspace.intelligence.read"]
        case .messaging:
            return ["workspace.mail.read"]
        case .fileSystem:
            return ["workspace.files.read", "workspace.files.write"]
        case .aiProcessing:
            return ["workspace.persona.read"]
        case .connectorBinding:
            return ["external.api.unrestricted"]
        case .pluginHosting:
            return ["workspace.plugins.execute"]
        case .eventPublishing:
            return ["workspace.automation.execute"]
        case .backgroundExecution:
            return ["workspace.runtime.admin"]
        }
    }
}

public extension PluginPermission {
    var requiredScope: String {
        switch self {
        case .readData:
            return "workspace.files.read"
        case .writeData:
            return "workspace.files.write"
        case .network:
            return "external.api.unrestricted"
        case .notifications:
            return "workspace.notifications.send"
        case .fileAccess:
            return "workspace.files.write"
        }
    }
}

public extension SDKPlugin {
    var requiredScopes: [String] {
        Array(Set(permissions.map(\.requiredScope))).sorted()
    }
}

public extension SDKPluginManifest {
    var requiredScopes: [String] {
        let declared = permissions.map(\.requiredScope)
        return Array(Set(declared)).sorted()
    }
}

public extension SDKAppDefinition {
    var requiredScopes: [String] {
        let normalized = permissions
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return Array(Set(normalized)).sorted()
    }
}
