import Foundation

public struct SDKScope: OptionSet, Codable, Hashable {
    public let rawValue: UInt64

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    // Workspace Scopes
    public static let workspaceRead          = SDKScope(rawValue: 1 << 0)
    public static let workspaceWrite         = SDKScope(rawValue: 1 << 1)

    // SDK Project Scopes
    public static let sdkProjectCreate       = SDKScope(rawValue: 1 << 2)

    // Management Scopes
    public static let sdkManageLibraries     = SDKScope(rawValue: 1 << 3)
    public static let sdkManageFrameworks    = SDKScope(rawValue: 1 << 4)
    public static let sdkManagePackages      = SDKScope(rawValue: 1 << 5)

    // Execution Scopes
    public static let frameworkExecute       = SDKScope(rawValue: 1 << 6)
    public static let libraryInvoke          = SDKScope(rawValue: 1 << 7)

    // Agent Scopes
    public static let agentExecute           = SDKScope(rawValue: 1 << 8)
    public static let agentTakeover          = SDKScope(rawValue: 1 << 9)

    public static let all: SDKScope = [
        .workspaceRead, .workspaceWrite, .sdkProjectCreate,
        .sdkManageLibraries, .sdkManageFrameworks, .sdkManagePackages,
        .frameworkExecute, .libraryInvoke, .agentExecute, .agentTakeover
    ]
}

public extension SDKModuleDescriptor {
    var requiredSDKScope: SDKScope {
        let mapped = capabilities.map(\.requiredSDKScope)
        return mapped.reduce(into: SDKScope()) { $0.formUnion($1) }
    }
}

public extension SDKModuleCapability {
    var requiredSDKScope: SDKScope {
        switch self {
        case .dataAccess, .rendering:
            return .workspaceRead
        case .networking, .connectorBinding:
            return .workspaceRead // Needs refinement based on actual logic
        case .storage, .fileSystem:
            return [.workspaceRead, .workspaceWrite]
        case .automation, .eventPublishing:
            return .frameworkExecute
        case .authentication, .backgroundExecution:
            return .workspaceWrite
        case .analytics:
            return .workspaceRead
        case .messaging:
            return .workspaceRead
        case .aiProcessing:
            return .agentExecute
        case .pluginHosting:
            return .frameworkExecute
        }
    }
}

public extension PluginPermission {
    var requiredSDKScope: SDKScope {
        switch self {
        case .readData:
            return .workspaceRead
        case .writeData, .fileAccess:
            return .workspaceWrite
        case .network:
            return .workspaceRead
        case .notifications:
            return .workspaceWrite
        }
    }
}

public extension SDKPlugin {
    var requiredSDKScope: SDKScope {
        permissions.map(\.requiredSDKScope).reduce(into: SDKScope()) { $0.formUnion($1) }
    }
}

public extension SDKPluginManifest {
    var requiredSDKScope: SDKScope {
        permissions.map(\.requiredSDKScope).reduce(into: SDKScope()) { $0.formUnion($1) }
    }
}

public extension SDKAppDefinition {
    var requiredSDKScope: SDKScope {
        // Mapping string permissions to SDKScope - simplified for now
        var scopes: SDKScope = []
        for perm in permissions {
            if perm.contains("read") { scopes.insert(.workspaceRead) }
            if perm.contains("write") { scopes.insert(.workspaceWrite) }
            if perm.contains("execute") { scopes.insert(.frameworkExecute) }
            if perm.contains("agent") { scopes.insert(.agentExecute) }
        }
        return scopes
    }
}
