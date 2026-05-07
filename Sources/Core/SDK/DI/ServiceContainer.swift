import Foundation

/// High-level service container that manages the SDK's dependency graph.
/// Provides convenient registration and resolution of all SDK services.
public final class ServiceContainer {
    public static let shared = ServiceContainer()

    private let registry = ServiceRegistry.shared

    private init() {}

    // MARK: - Default Registration

    public func registerDefaults() {
        registry.register(SDKDataStoreProtocol.self) { SDKDataStore.shared }
        registry.register(SDKEventBusProtocol.self) { SDKEventBus.shared }
        registry.register(SDKRouterProtocol.self) { SDKRouter.shared }
        registry.register(SDKPermissionManagerProtocol.self) { SDKPermissionManager.shared }
        registry.register(PluginRuntimeProtocol.self) { PluginRuntimeEngine.shared }
        registry.register(SDKMailServiceProtocol.self) { SDKMailService.shared }
        registry.register(SDKNotebookServiceProtocol.self) { SDKNotebookService.shared }
        registry.register(SDKMeetServiceProtocol.self) { SDKMeetService.shared }
        registry.register(SDKArticleServiceProtocol.self) { SDKArticleService.shared }
    }

    // MARK: - Convenience Resolution

    public func resolve<T>(_ type: T.Type) -> T? {
        return registry.resolve(type)
    }

    public func resolveRequired<T>(_ type: T.Type) throws -> T {
        return try registry.resolveRequired(type)
    }

    // MARK: - Custom Registration

    public func register<T>(_ type: T.Type, scope: ServiceRegistry.ServiceScope = .singleton, factory: @escaping () -> T) {
        registry.register(type, scope: scope, factory: factory)
    }

    // MARK: - Inspection

    public func registeredServiceNames() -> [String] {
        return registry.registeredTypes()
    }

    public func isRegistered<T>(_ type: T.Type) -> Bool {
        return registry.isRegistered(type)
    }
}
