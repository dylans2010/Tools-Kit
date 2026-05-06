import Foundation
import Combine

/// Centralized state management for SDK applications.
public final class SDKStateStore: ObservableObject {
    public static let shared = SDKStateStore()

    @Published private var state: [String: AnyCodable] = [:]

    private init() {}

    public func set(_ value: AnyCodable, for key: String) {
        state[key] = value
    }

    public func get<T: Decodable>(_ key: String, as type: T.Type) -> T? {
        guard let value = state[key] else { return nil }
        return value.value as? T
    }
}

public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Bool.self) { value = x }
        else if let x = try? container.decode(Int.self) { value = x }
        else if let x = try? container.decode(Double.self) { value = x }
        else if let x = try? container.decode(String.self) { value = x }
        else if let x = try? container.decode([AnyCodable].self) { value = x.map { $0.value } }
        else if let x = try? container.decode([String: AnyCodable].self) { value = x.mapValues { $0.value } }
        else { throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported AnyCodable type") }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let x as Bool: try container.encode(x)
        case let x as Int: try container.encode(x)
        case let x as Double: try container.encode(x)
        case let x as String: try container.encode(x)
        case let x as [Any]: try container.encode(x.map { AnyCodable($0) })
        case let x as [String: Any]: try container.encode(x.mapValues { AnyCodable($0) })
        default: throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "AnyCodable value is not encodable"))
        }
    }
}
