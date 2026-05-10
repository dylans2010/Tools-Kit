// ToolsKit — SDKErrorDomains.swift
// SDK Expansion — Phase 3

import Foundation

/// Protocol for all SDK error domains.
public protocol SDKErrorDomain: Error, Sendable, CustomStringConvertible {
    var errorCode: Int { get }
    var domain: String { get }
}

/// Errors related to the SDK Core kernel and lifecycle.
public enum SDKKernelError: Error, Sendable {
    case bootFailed(reason: String)
    case shutdownFailed(reason: String)
    case invalidStateTransition(from: String, to: String)
    case serviceUnavailable(service: String)
    case timeout(operation: String, seconds: TimeInterval)

    public var errorCode: Int {
        switch self {
        case .bootFailed: return 1001
        case .shutdownFailed: return 1002
        case .invalidStateTransition: return 1003
        case .serviceUnavailable: return 1004
        case .timeout: return 1005
        }
    }

    public var domain: String { "com.toolskit.sdk.kernel" }
}

extension SDKKernelError: SDKErrorDomain {
    public var description: String {
        switch self {
        case .bootFailed(let reason): return "Kernel boot failed: \(reason)"
        case .shutdownFailed(let reason): return "Kernel shutdown failed: \(reason)"
        case .invalidStateTransition(let from, let to): return "Invalid state transition from \(from) to \(to)"
        case .serviceUnavailable(let service): return "Service unavailable: \(service)"
        case .timeout(let operation, let seconds): return "Operation '\(operation)' timed out after \(seconds)s"
        }
    }
}

/// Errors related to plugin operations.
public enum SDKPluginError: Error, Sendable {
    case notFound(identifier: String)
    case alreadyRegistered(identifier: String)
    case lifecycleViolation(phase: String, attempted: String)
    case dependencyMissing(plugin: String, dependency: String)
    case activationFailed(identifier: String, reason: String)
    case sandboxViolation(identifier: String, scope: String)

    public var errorCode: Int {
        switch self {
        case .notFound: return 2001
        case .alreadyRegistered: return 2002
        case .lifecycleViolation: return 2003
        case .dependencyMissing: return 2004
        case .activationFailed: return 2005
        case .sandboxViolation: return 2006
        }
    }

    public var domain: String { "com.toolskit.sdk.plugin" }
}

extension SDKPluginError: SDKErrorDomain {
    public var description: String {
        switch self {
        case .notFound(let id): return "Plugin not found: \(id)"
        case .alreadyRegistered(let id): return "Plugin already registered: \(id)"
        case .lifecycleViolation(let phase, let attempted): return "Lifecycle violation: cannot transition from \(phase) to \(attempted)"
        case .dependencyMissing(let plugin, let dep): return "Plugin '\(plugin)' missing dependency: \(dep)"
        case .activationFailed(let id, let reason): return "Plugin '\(id)' activation failed: \(reason)"
        case .sandboxViolation(let id, let scope): return "Sandbox violation for plugin '\(id)' on scope '\(scope)'"
        }
    }
}

/// Errors related to connector operations.
public enum SDKConnectorError: Error, Sendable {
    case connectionFailed(connector: String, reason: String)
    case authenticationFailed(connector: String)
    case syncFailed(connector: String, reason: String)
    case invalidConfiguration(connector: String, field: String)
    case rateLimited(connector: String, retryAfter: TimeInterval)
    case disconnected(connector: String)

    public var errorCode: Int {
        switch self {
        case .connectionFailed: return 3001
        case .authenticationFailed: return 3002
        case .syncFailed: return 3003
        case .invalidConfiguration: return 3004
        case .rateLimited: return 3005
        case .disconnected: return 3006
        }
    }

    public var domain: String { "com.toolskit.sdk.connector" }
}

extension SDKConnectorError: SDKErrorDomain {
    public var description: String {
        switch self {
        case .connectionFailed(let c, let r): return "Connection failed for '\(c)': \(r)"
        case .authenticationFailed(let c): return "Authentication failed for connector '\(c)'"
        case .syncFailed(let c, let r): return "Sync failed for '\(c)': \(r)"
        case .invalidConfiguration(let c, let f): return "Invalid configuration for '\(c)': field '\(f)'"
        case .rateLimited(let c, let t): return "Rate limited for '\(c)', retry after \(t)s"
        case .disconnected(let c): return "Connector '\(c)' is disconnected"
        }
    }
}

/// Errors related to data store operations.
public enum SDKDataError: Error, Sendable {
    case saveFailed(model: String, reason: String)
    case fetchFailed(model: String, id: String)
    case migrationFailed(fromVersion: Int, toVersion: Int, reason: String)
    case corruptedData(collection: String)
    case collectionNotFound(name: String)

    public var errorCode: Int {
        switch self {
        case .saveFailed: return 4001
        case .fetchFailed: return 4002
        case .migrationFailed: return 4003
        case .corruptedData: return 4004
        case .collectionNotFound: return 4005
        }
    }

    public var domain: String { "com.toolskit.sdk.data" }
}

extension SDKDataError: SDKErrorDomain {
    public var description: String {
        switch self {
        case .saveFailed(let m, let r): return "Failed to save \(m): \(r)"
        case .fetchFailed(let m, let id): return "Failed to fetch \(m) with id \(id)"
        case .migrationFailed(let from, let to, let r): return "Migration from v\(from) to v\(to) failed: \(r)"
        case .corruptedData(let c): return "Corrupted data in collection '\(c)'"
        case .collectionNotFound(let n): return "Collection '\(n)' not found"
        }
    }
}

/// Errors related to network operations.
public enum SDKNetworkError: Error, Sendable {
    case requestFailed(url: String, statusCode: Int)
    case invalidURL(string: String)
    case noResponse(url: String)
    case decodingFailed(type: String, reason: String)
    case sslError(host: String)
    case cancelled

    public var errorCode: Int {
        switch self {
        case .requestFailed: return 5001
        case .invalidURL: return 5002
        case .noResponse: return 5003
        case .decodingFailed: return 5004
        case .sslError: return 5005
        case .cancelled: return 5006
        }
    }

    public var domain: String { "com.toolskit.sdk.network" }
}

extension SDKNetworkError: SDKErrorDomain {
    public var description: String {
        switch self {
        case .requestFailed(let url, let code): return "Request to '\(url)' failed with status \(code)"
        case .invalidURL(let s): return "Invalid URL: \(s)"
        case .noResponse(let url): return "No response from '\(url)'"
        case .decodingFailed(let t, let r): return "Failed to decode \(t): \(r)"
        case .sslError(let h): return "SSL error for host '\(h)'"
        case .cancelled: return "Network request cancelled"
        }
    }
}
