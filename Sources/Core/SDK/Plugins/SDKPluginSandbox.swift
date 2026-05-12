import Foundation

@MainActor
public final class SDKPluginSandbox {
    nonisolated(unsafe) public static let shared = SDKPluginSandbox()

    @Published public var executionLog: [SandboxEvent] = []
    @Published public var activeExecutions: [UUID: SandboxContext] = [:]

    private init() {}

    public struct SandboxContext: Sendable {
        public let pluginID: UUID
        public let pluginName: String
        public let grantedPermissions: Set<PluginPermission>
        public let startedAt: Date
        public var resourceUsage: ResourceUsage

        public struct ResourceUsage: Sendable {
            public var networkRequestCount: Int = 0
            public var dataReadBytes: Int = 0
            public var dataWriteBytes: Int = 0
        }
    }

    public struct SandboxEvent: Identifiable, Sendable {
        public let id: UUID
        public let pluginID: UUID
        public let action: String
        public let allowed: Bool
        public let timestamp: Date
    }

    public func beginExecution(plugin: SDKPlugin) throws -> SandboxContext {
        guard plugin.isEnabled else {
            throw SDKPluginError.activationFailed(identifier: plugin.name, reason: "Plugin is disabled")
        }

        let context = SandboxContext(
            pluginID: plugin.id,
            pluginName: plugin.name,
            grantedPermissions: Set(plugin.permissions),
            startedAt: Date(),
            resourceUsage: .init()
        )

        activeExecutions[plugin.id] = context
        logEvent(pluginID: plugin.id, action: "execution.started", allowed: true)

        return context
    }

    public func checkPermission(_ permission: PluginPermission, for pluginID: UUID) -> Bool {
        guard let context = activeExecutions[pluginID] else { return false }
        let allowed = context.grantedPermissions.contains(permission)
        logEvent(pluginID: pluginID, action: "permission.\(permission.rawValue)", allowed: allowed)
        return allowed
    }

    public func recordNetworkRequest(for pluginID: UUID) {
        activeExecutions[pluginID]?.resourceUsage.networkRequestCount += 1
    }

    public func recordDataRead(bytes: Int, for pluginID: UUID) {
        activeExecutions[pluginID]?.resourceUsage.dataReadBytes += bytes
    }

    public func recordDataWrite(bytes: Int, for pluginID: UUID) {
        activeExecutions[pluginID]?.resourceUsage.dataWriteBytes += bytes
    }

    public func endExecution(for pluginID: UUID) {
        activeExecutions.removeValue(forKey: pluginID)
        logEvent(pluginID: pluginID, action: "execution.ended", allowed: true)
    }

    private func logEvent(pluginID: UUID, action: String, allowed: Bool) {
        let event = SandboxEvent(
            id: UUID(),
            pluginID: pluginID,
            action: action,
            allowed: allowed,
            timestamp: Date()
        )
        executionLog.insert(event, at: 0)
        if executionLog.count > 500 {
            executionLog = Array(executionLog.prefix(500))
        }
    }
}
