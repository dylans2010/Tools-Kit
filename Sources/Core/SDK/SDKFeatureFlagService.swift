// ToolsKit — SDKFeatureFlagService.swift
// SDK Expansion — Phase 3

import Foundation
import Combine

/// Protocol for feature flag evaluation.
@MainActor
public protocol SDKFeatureFlagServiceProtocol: AnyObject {
    func isEnabled(_ flag: String) -> Bool
    func setFlag(_ flag: String, enabled: Bool)
    func removeFlag(_ flag: String)
    var allFlags: [SDKFeatureFlag] { get }
}

/// Represents a single feature flag with metadata.
public struct SDKFeatureFlag: Identifiable, Codable, Sendable {
    public let id: String
    public var name: String
    public var isEnabled: Bool
    public var description: String
    public var createdAt: Date
    public var updatedAt: Date
    public var category: String
    public var overrideSource: OverrideSource

    public enum OverrideSource: String, Codable, Sendable, CaseIterable {
        case local
        case remote
        case defaultValue
    }

    public init(
        name: String,
        isEnabled: Bool = false,
        description: String = "",
        category: String = "general",
        overrideSource: OverrideSource = .local
    ) {
        self.id = name
        self.name = name
        self.isEnabled = isEnabled
        self.description = description
        self.createdAt = Date()
        self.updatedAt = Date()
        self.category = category
        self.overrideSource = overrideSource
    }
}

/// Centralized feature flag management with persistence and event publishing.
@MainActor
public final class SDKFeatureFlagService: SDKFeatureFlagServiceProtocol, ObservableObject {
    public static let shared = SDKFeatureFlagService()

    @Published public private(set) var flags: [String: SDKFeatureFlag] = [:]

    private let persistenceKey = "sdk_feature_flags_v1"

    private init() {
        loadFlags()
        registerDefaultFlags()
    }

    public func isEnabled(_ flag: String) -> Bool {
        flags[flag]?.isEnabled ?? false
    }

    public func setFlag(_ flag: String, enabled: Bool) {
        if var existing = flags[flag] {
            existing.isEnabled = enabled
            existing.updatedAt = Date()
            existing.overrideSource = .local
            flags[flag] = existing
        } else {
            flags[flag] = SDKFeatureFlag(name: flag, isEnabled: enabled)
        }
        saveFlags()

        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.featureflags",
            name: "flag.changed",
            data: ["flag": flag, "enabled": "\(enabled)"]
        ))
    }

    public func removeFlag(_ flag: String) {
        flags.removeValue(forKey: flag)
        saveFlags()
    }

    public var allFlags: [SDKFeatureFlag] {
        Array(flags.values).sorted { $0.name < $1.name }
    }

    public func flags(inCategory category: String) -> [SDKFeatureFlag] {
        allFlags.filter { $0.category == category }
    }

    public var categories: [String] {
        Array(Set(flags.values.map { $0.category })).sorted()
    }

    public func registerFlag(_ flag: SDKFeatureFlag) {
        if flags[flag.name] == nil {
            flags[flag.name] = flag
            saveFlags()
        }
    }

    public func resetToDefaults() {
        flags.removeAll()
        registerDefaultFlags()
        saveFlags()
    }

    private func registerDefaultFlags() {
        let defaults: [SDKFeatureFlag] = [
            SDKFeatureFlag(name: "sdk.debug.verbose", isEnabled: false, description: "Enable verbose debug logging", category: "debug"),
            SDKFeatureFlag(name: "sdk.cache.enabled", isEnabled: true, description: "Enable in-memory caching", category: "performance"),
            SDKFeatureFlag(name: "sdk.metrics.enabled", isEnabled: true, description: "Enable metrics collection", category: "performance"),
            SDKFeatureFlag(name: "sdk.health.autoMonitor", isEnabled: false, description: "Enable automatic health monitoring", category: "health"),
            SDKFeatureFlag(name: "sdk.retry.enabled", isEnabled: true, description: "Enable automatic retry on failures", category: "reliability"),
            SDKFeatureFlag(name: "sdk.plugins.sandbox", isEnabled: true, description: "Enable plugin sandboxing", category: "security"),
            SDKFeatureFlag(name: "sdk.connectors.autoReconnect", isEnabled: true, description: "Auto-reconnect failed connectors", category: "connectors"),
            SDKFeatureFlag(name: "sdk.notifications.enabled", isEnabled: true, description: "Enable SDK notifications", category: "notifications"),
        ]

        for flag in defaults {
            if flags[flag.name] == nil {
                flags[flag.name] = flag
            }
        }
    }

    private func saveFlags() {
        if let data = try? JSONEncoder().encode(Array(flags.values)) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }

    private func loadFlags() {
        guard let data = UserDefaults.standard.data(forKey: persistenceKey),
              let loaded = try? JSONDecoder().decode([SDKFeatureFlag].self, from: data)
        else { return }

        for flag in loaded {
            flags[flag.name] = flag
        }
    }
}
