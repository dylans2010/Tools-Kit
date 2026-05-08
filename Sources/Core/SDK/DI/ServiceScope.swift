import Foundation

/// Defines the lifetime and visibility of a service within the SDK.
public enum ServiceScope: String, Codable, CaseIterable {
    /// A single instance is shared across the entire SDK lifecycle.
    case singleton

    /// A new instance is created every time the service is resolved.
    case transient

    /// An instance is shared within a specific execution context or request.
    case scoped

    /// An instance that is tied to a specific workspace.
    case workspace
}
