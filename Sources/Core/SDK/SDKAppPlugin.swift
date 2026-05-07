import Foundation

/// Protocol for all WorkspaceSDK Apps.
public protocol SDKApp: Identifiable {
    var id: UUID { get }
    var name: String { get }
    var version: String { get }
    var author: String { get }

    func onInitialize() async
    func onStart() async
    func onStop() async
}

/// Protocol for all WorkspaceSDK Plugins.
public protocol SDKPlugin: Identifiable {
    var id: UUID { get }
    var name: String { get }
    var identifier: String { get }
    var requiredScopes: [SDKPermissionManager.PermissionScope] { get }

    func execute(action: String, parameters: [String: Any]) async throws -> Any?
}
