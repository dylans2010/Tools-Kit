import Foundation

/// Property wrapper for dependency injection.
/// Resolves services lazily from the ServiceRegistry.
///
/// Usage:
/// ```swift
/// @ServiceInjected var dataStore: SDKDataStoreProtocol
/// @ServiceInjected var eventBus: SDKEventBusProtocol
/// ```
@propertyWrapper
public struct ServiceInjected<T> {
    private var service: T?

    public init() {}

    public var wrappedValue: T {
        mutating get {
            if let service = service {
                return service
            }
            guard let resolved = ServiceRegistry.shared.resolve(T.self) else {
                fatalError("Service \(String(describing: T.self)) not registered in ServiceRegistry")
            }
            service = resolved
            return resolved
        }
    }
}
