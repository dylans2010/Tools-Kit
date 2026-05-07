import Foundation

/// Runtime context for SDK operations.
/// Carries request-scoped metadata through the execution pipeline.
public final class SDKContext {
    public let id: UUID
    public let createdAt: Date
    public let scope: ContextScope
    public private(set) var metadata: [String: String]
    public private(set) var permissions: Set<String>
    public let parentContext: SDKContext?

    public enum ContextScope: String, Codable {
        case global, workspace, feature, plugin, request
    }

    public init(
        id: UUID = UUID(),
        scope: ContextScope = .request,
        metadata: [String: String] = [:],
        permissions: Set<String> = [],
        parent: SDKContext? = nil
    ) {
        self.id = id
        self.createdAt = Date()
        self.scope = scope
        self.metadata = metadata
        self.permissions = permissions
        self.parentContext = parent
    }

    public func withMetadata(_ key: String, _ value: String) -> SDKContext {
        let ctx = SDKContext(
            id: id,
            scope: scope,
            metadata: metadata,
            permissions: permissions,
            parent: parentContext
        )
        ctx.metadata[key] = value
        return ctx
    }

    public func hasPermission(_ permission: String) -> Bool {
        if permissions.contains("*") { return true }
        if permissions.contains(permission) { return true }
        return parentContext?.hasPermission(permission) ?? false
    }

    public static func global() -> SDKContext {
        return SDKContext(scope: .global, permissions: ["*"])
    }

    public static func feature(_ name: String) -> SDKContext {
        return SDKContext(
            scope: .feature,
            metadata: ["feature": name],
            permissions: ["read", "write"],
            parent: global()
        )
    }
}
