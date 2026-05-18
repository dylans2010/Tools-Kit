import Foundation
import Combine

public enum ConfigSource: String, Codable, CaseIterable, Hashable {
    case `default`
    case user
    case profile
    case remote
}

public struct SDKConfigEntry: Identifiable, Codable, Hashable, Equatable {
    public let id: UUID
    public let key: String
    public var value: String
    public var source: ConfigSource
    public init(id: UUID = UUID(), key: String, value: String,
                source: ConfigSource = .default) {
        self.id = id; self.key = key
        self.value = value; self.source = source
    }
}

public struct ConfigChange: Codable, Hashable, Equatable {
    public let key: String
    public let oldValue: String?
    public let newValue: String
    public let source: ConfigSource
}

public class SDKConfigManager: ObservableObject {
    public static let shared = SDKConfigManager()
    @Published public var entries: [SDKConfigEntry] = []
    @Published public var changes: [ConfigChange] = []
    private init() {}
    public func set(_ key: String, value: String,
                    source: ConfigSource = .user) {
        if let i = entries.firstIndex(where: { $0.key == key }) {
            let old = entries[i].value
            entries[i].value = value
            changes.append(ConfigChange(key: key, oldValue: old,
                                        newValue: value, source: source))
        } else {
            entries.append(SDKConfigEntry(key: key, value: value,
                                          source: source))
        }
    }
}
