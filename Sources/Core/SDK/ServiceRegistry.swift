import Foundation

/// A central registry for all SDK services.
public final class ServiceRegistry {
    public static let shared = ServiceRegistry()

    private var services: [String: Any] = [:]
    private let lock = NSRecursiveLock()

    private init() {}

    public func register<T>(_ service: T, for type: T.Type) {
        lock.lock()
        defer { lock.unlock() }
        let key = String(describing: type)
        services[key] = service
    }

    public func resolve<T>(_ type: T.Type) -> T {
        lock.lock()
        defer { lock.unlock() }
        let key = String(describing: type)
        guard let service = services[key] as? T else {
            fatalError("Service \(key) not registered")
        }
        return service
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        services.removeAll()
    }
}
