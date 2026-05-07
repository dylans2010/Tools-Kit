import Foundation

/// SDK-wide configuration and environment settings.
/// Manages build configuration, feature flags, and runtime parameters.
public final class SDKEnvironment: ObservableObject {
    public static let shared = SDKEnvironment()

    @Published public private(set) var configuration: SDKConfiguration
    @Published public private(set) var featureFlags: [String: Bool] = [:]

    private let persistenceKey = "sdk_environment_config"

    public struct SDKConfiguration: Codable {
        public var sdkVersion: String
        public var buildNumber: Int
        public var environment: Environment
        public var logLevel: LogLevel
        public var maxCacheSizeMB: Int
        public var eventHistoryLimit: Int
        public var pluginSandboxEnabled: Bool
        public var offlineMode: Bool
        public var dataEncryptionEnabled: Bool
        public var analyticsEnabled: Bool

        public enum Environment: String, Codable, CaseIterable {
            case development, staging, production
        }

        public static var `default`: SDKConfiguration {
            SDKConfiguration(
                sdkVersion: "2.0.0",
                buildNumber: 1,
                environment: .development,
                logLevel: .info,
                maxCacheSizeMB: 50,
                eventHistoryLimit: 1000,
                pluginSandboxEnabled: true,
                offlineMode: false,
                dataEncryptionEnabled: false,
                analyticsEnabled: true
            )
        }
    }

    private init() {
        configuration = .default
    }

    public func load() {
        if let data = UserDefaults.standard.data(forKey: persistenceKey),
           let decoded = try? JSONDecoder().decode(SDKConfiguration.self, from: data) {
            configuration = decoded
        }
        loadFeatureFlags()
    }

    public func save() {
        if let data = try? JSONEncoder().encode(configuration) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }

    public func update(_ transform: (inout SDKConfiguration) -> Void) {
        transform(&configuration)
        save()
    }

    public func setFeatureFlag(_ key: String, enabled: Bool) {
        featureFlags[key] = enabled
        persistFeatureFlags()
    }

    public func isFeatureEnabled(_ key: String) -> Bool {
        return featureFlags[key] ?? false
    }

    private func loadFeatureFlags() {
        if let data = UserDefaults.standard.data(forKey: "sdk_feature_flags"),
           let decoded = try? JSONDecoder().decode([String: Bool].self, from: data) {
            featureFlags = decoded
        }
    }

    private func persistFeatureFlags() {
        if let data = try? JSONEncoder().encode(featureFlags) {
            UserDefaults.standard.set(data, forKey: "sdk_feature_flags")
        }
    }
}
