import Foundation

public enum RemoteConfigValueType: String, Codable, CaseIterable {
    case string = "String"
    case json = "JSON"
    case boolean = "Boolean"
    case number = "Number"
}

public struct RemoteConfig: Identifiable, Codable, Hashable {
    public var id: UUID
    public var key: String
    public var value: String
    public var valueType: RemoteConfigValueType
    public var environment: KeyEnvironment
    public var version: Int

    public init(id: UUID = UUID(), key: String, value: String, valueType: RemoteConfigValueType = .string, environment: KeyEnvironment = .live, version: Int = 1) {
        self.id = id
        self.key = key
        self.value = value
        self.valueType = valueType
        self.environment = environment
        self.version = version
    }
}
