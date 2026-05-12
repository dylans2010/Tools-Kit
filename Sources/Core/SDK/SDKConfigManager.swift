import Foundation
import Combine

@MainActor
public final class SDKConfigManager: ObservableObject {
    nonisolated(unsafe) public static let shared = SDKConfigManager()

    @Published public private(set) var configurations: [String: SDKConfigEntry] = [:]
    @Published public private(set) var profiles: [SDKConfigProfile] = []
    @Published public private(set) var activeProfileID: UUID?
    @Published public private(set) var changeLog: [ConfigChange] = []

    private let storageKey = "sdk.config.store"

    private init() {
        loadDefaults()
    }

    // MARK: - Get/Set

    public func get(_ key: String) -> String? {
        configurations[key]?.value
    }

    public func get(_ key: String, default defaultValue: String) -> String {
        configurations[key]?.value ?? defaultValue
    }

    public func getBool(_ key: String, default defaultValue: Bool = false) -> Bool {
        guard let value = configurations[key]?.value else { return defaultValue }
        return value == "true" || value == "1" || value == "yes"
    }

    public func getInt(_ key: String, default defaultValue: Int = 0) -> Int {
        guard let value = configurations[key]?.value else { return defaultValue }
        return Int(value) ?? defaultValue
    }

    public func getDouble(_ key: String, default defaultValue: Double = 0) -> Double {
        guard let value = configurations[key]?.value else { return defaultValue }
        return Double(value) ?? defaultValue
    }

    public func set(_ key: String, value: String, source: ConfigSource = .user) {
        let old = configurations[key]?.value
        configurations[key] = SDKConfigEntry(key: key, value: value, source: source)
        changeLog.append(ConfigChange(key: key, oldValue: old, newValue: value, source: source))
        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.config",
            name: "config.changed",
            data: ["key": key, "value": value]
        ))
    }

    public func remove(_ key: String) {
        let old = configurations[key]?.value
        configurations.removeValue(forKey: key)
        if let old {
            changeLog.append(ConfigChange(key: key, oldValue: old, newValue: nil, source: .user))
        }
    }

    // MARK: - Profiles

    public func createProfile(name: String, values: [String: String] = [:]) -> SDKConfigProfile {
        let profile = SDKConfigProfile(name: name, values: values)
        profiles.append(profile)
        return profile
    }

    public func activateProfile(id: UUID) {
        guard let profile = profiles.first(where: { $0.id == id }) else { return }
        activeProfileID = id
        for (key, value) in profile.values {
            set(key, value: value, source: .profile)
        }
        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.config",
            name: "profile.activated",
            data: ["profile": profile.name]
        ))
    }

    public func deleteProfile(id: UUID) {
        profiles.removeAll { $0.id == id }
        if activeProfileID == id { activeProfileID = nil }
    }

    // MARK: - Export/Import

    public func exportAll() -> [String: String] {
        configurations.reduce(into: [:]) { $0[$1.key] = $1.value.value }
    }

    public func importAll(_ values: [String: String], source: ConfigSource = .imported) {
        for (key, value) in values {
            set(key, value: value, source: source)
        }
    }

    // MARK: - Inspection

    public func keys(matching prefix: String) -> [String] {
        configurations.keys.filter { $0.hasPrefix(prefix) }.sorted()
    }

    public func entries(from source: ConfigSource) -> [SDKConfigEntry] {
        configurations.values.filter { $0.source == source }.sorted { $0.key < $1.key }
    }

    // MARK: - Defaults

    private func loadDefaults() {
        let defaults: [String: String] = [
            "sdk.debug.enabled": "false",
            "sdk.analytics.enabled": "true",
            "sdk.cache.maxSize": "100",
            "sdk.network.timeout": "30",
            "sdk.log.level": "info",
            "sdk.theme": "system",
            "sdk.locale": "en",
            "sdk.sync.interval": "60",
            "sdk.notifications.enabled": "true",
            "sdk.experimental.features": "false"
        ]
        for (key, value) in defaults {
            if configurations[key] == nil {
                configurations[key] = SDKConfigEntry(key: key, value: value, source: .default)
            }
        }
    }
}

// MARK: - Models

public struct SDKConfigEntry: Identifiable, Codable, Sendable {
    public var id: String { key }
    public let key: String
    public let value: String
    public let source: ConfigSource
    public let updatedAt: Date

    public init(key: String, value: String, source: ConfigSource = .default) {
        self.key = key
        self.value = value
        self.source = source
        self.updatedAt = Date()
    }
}

public enum ConfigSource: String, Codable, CaseIterable, Sendable {
    case `default`, user, profile, environment, imported, remote
}

public struct SDKConfigProfile: Identifiable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var values: [String: String]
    public let createdAt: Date

    public init(name: String, values: [String: String] = [:]) {
        self.id = UUID()
        self.name = name
        self.values = values
        self.createdAt = Date()
    }
}

public struct ConfigChange: Identifiable, Codable, Sendable {
    public let id: UUID
    public let key: String
    public let oldValue: String?
    public let newValue: String?
    public let source: ConfigSource
    public let timestamp: Date

    public init(key: String, oldValue: String?, newValue: String?, source: ConfigSource) {
        self.id = UUID()
        self.key = key
        self.oldValue = oldValue
        self.newValue = newValue
        self.source = source
        self.timestamp = Date()
    }
}
