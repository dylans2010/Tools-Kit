import Foundation

/// Protocol-based service registry for the SDK dependency injection system.
/// Services are registered by protocol type and resolved lazily.
public final class ServiceRegistry {
    public static let shared = ServiceRegistry()

    private var factories: [String: () -> Any] = [:]
    private var singletons: [String: Any] = [:]
    private var scopes: [String: ServiceScope] = [:]
    private let lock = NSRecursiveLock()

    public enum ServiceScope: String {
        case singleton, transient, scoped
    }

    private init() {}

    // MARK: - Registration

    public func register<T>(_ type: T.Type, scope: ServiceScope = .singleton, factory: @escaping () -> T) {
        let key = String(describing: type)
        lock.lock()
        defer { lock.unlock() }
        factories[key] = factory
        scopes[key] = scope
        if scope != .singleton {
            singletons.removeValue(forKey: key)
        }
    }

    // MARK: - Resolution

    public func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        lock.lock()
        defer { lock.unlock() }

        let scope = scopes[key] ?? .singleton

        switch scope {
        case .singleton:
            if let existing = singletons[key] as? T {
                return existing
            }
            guard let factory = factories[key] else { return nil }
            let instance = factory() as! T
            singletons[key] = instance
            return instance

        case .transient:
            guard let factory = factories[key] else { return nil }
            return factory() as? T

        case .scoped:
            if let existing = singletons[key] as? T {
                return existing
            }
            guard let factory = factories[key] else { return nil }
            let instance = factory() as! T
            singletons[key] = instance
            return instance
        }
    }

    public func resolveRequired<T>(_ type: T.Type) throws -> T {
        guard let service = resolve(type) else {
            throw SDKError.executionFailed(reason: "Service not found: \(String(describing: type))")
        }
        return service
    }

    // MARK: - Inspection

    public func isRegistered<T>(_ type: T.Type) -> Bool {
        let key = String(describing: type)
        lock.lock()
        defer { lock.unlock() }
        return factories[key] != nil
    }

    public func registeredTypes() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(factories.keys)
    }

    // MARK: - Lifecycle

    public func clearScope(_ scope: ServiceScope) {
        lock.lock()
        defer { lock.unlock() }
        let keys = scopes.filter { $0.value == scope }.map { $0.key }
        for key in keys {
            singletons.removeValue(forKey: key)
        }
    }

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        singletons.removeAll()
    }
}
