import Foundation

/// Protocol defining an SDK Plugin.
/// Plugins are lightweight, background-oriented extensions.
public protocol SDKPlugin {
    var id: UUID { get }
    var name: String { get }
    var version: String { get }

    func onInstall() async throws
    func onUninstall() async throws
    func onEnable() async throws
    func onDisable() async throws
}

/// Base implementation for SDK Plugins.
open class BaseSDKPlugin: SDKPlugin {
    public let id: UUID
    public let name: String
    public let version: String

    public init(id: UUID = UUID(), name: String, version: String = "1.0.0") {
        self.id = id
        self.name = name
        self.version = version
    }

    open func onInstall() async throws {}
    open func onUninstall() async throws {}
    open func onEnable() async throws {}
    open func onDisable() async throws {}
}
