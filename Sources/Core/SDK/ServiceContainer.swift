import Foundation

/// A property wrapper for injecting SDK services.
@propertyWrapper
public struct ServiceInjected<T> {
    private var service: T

    public init() {
        self.service = ServiceRegistry.shared.resolve(T.self)
    }

    public var wrappedValue: T {
        get { service }
        mutating set { service = newValue }
    }
}

/// ServiceContainer manages the lifecycle and resolution of modular services.
public final class ServiceContainer {
    public static let shared = ServiceContainer()

    private init() {}

    public func setupCoreServices() {
        // Core services registration will be added here as they are implemented
    }
}
