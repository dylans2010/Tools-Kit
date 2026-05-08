import Foundation

/// Protocol defining an SDK App.
/// Apps are larger, feature-rich extensions with their own UI and lifecycle.
@MainActor
public protocol SDKApp: SDKAppLifecycle, Identifiable {
    var id: UUID { get }
    var definition: SDKAppDefinition { get }
}

/// Base implementation for SDK Apps.
open class BaseSDKApp: SDKApp {
    public let id: UUID
    public let definition: SDKAppDefinition

    public var appId: UUID { id }
    public var appName: String { definition.name }

    public init(definition: SDKAppDefinition) {
        self.id = definition.id
        self.definition = definition
    }

    open func onInit() async throws {}
    open func onStart() async throws {}
    open func onStop() async throws {}
}
