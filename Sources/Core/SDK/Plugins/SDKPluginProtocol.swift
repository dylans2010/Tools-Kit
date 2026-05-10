// ToolsKit — SDKPluginProtocol.swift
// SDK Expansion — Phase 4

import Foundation
import Combine

/// Core protocol that all SDK plugins must conform to.
@MainActor
public protocol SDKPluginConformable: AnyObject, Identifiable where ID == UUID {
    var pluginIdentifier: String { get }
    var pluginDisplayName: String { get }
    var pluginVersion: String { get }
    var pluginDescription: String { get }
    var pluginCategory: SDKPluginCategory { get }
    var requiredCapabilities: [SDKPluginCapability] { get }
    var requiredScopes: [String] { get }

    func onActivate() async throws
    func onDeactivate() async throws
    func onPause() async throws
    func onResume() async throws
    func healthCheck() async -> SDKHealthStatus
}

/// Plugin lifecycle delegate for receiving lifecycle events.
@MainActor
public protocol SDKPluginLifecycleDelegate: AnyObject {
    func pluginWillActivate(_ identifier: String)
    func pluginDidActivate(_ identifier: String)
    func pluginWillDeactivate(_ identifier: String)
    func pluginDidDeactivate(_ identifier: String)
    func pluginDidError(_ identifier: String, error: Error)
}

/// Extension providing default implementations.
extension SDKPluginLifecycleDelegate {
    public func pluginWillActivate(_ identifier: String) {}
    public func pluginDidActivate(_ identifier: String) {}
    public func pluginWillDeactivate(_ identifier: String) {}
    public func pluginDidDeactivate(_ identifier: String) {}
    public func pluginDidError(_ identifier: String, error: Error) {}
}

/// Category classification for plugins.
public enum SDKPluginCategory: String, Codable, Sendable, CaseIterable {
    case analytics
    case communication
    case dataProcessing
    case integration
    case monitoring
    case security
    case ui
    case utility
    case automation
    case storage
}

/// Runtime information for a registered plugin.
public struct SDKPluginInfo: Identifiable, Sendable {
    public let id: UUID
    public let identifier: String
    public let displayName: String
    public let version: String
    public let description: String
    public let category: SDKPluginCategory
    public let capabilities: [SDKPluginCapability]
    public let scopes: [String]
    public let phase: SDKPluginPhase
    public let registeredAt: Date

    public init(
        id: UUID,
        identifier: String,
        displayName: String,
        version: String,
        description: String,
        category: SDKPluginCategory,
        capabilities: [SDKPluginCapability],
        scopes: [String],
        phase: SDKPluginPhase,
        registeredAt: Date = Date()
    ) {
        self.id = id
        self.identifier = identifier
        self.displayName = displayName
        self.version = version
        self.description = description
        self.category = category
        self.capabilities = capabilities
        self.scopes = scopes
        self.phase = phase
        self.registeredAt = registeredAt
    }
}
