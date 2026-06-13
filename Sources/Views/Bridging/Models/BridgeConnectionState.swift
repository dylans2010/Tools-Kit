import Foundation
import SwiftUI

/// Represents the current state of the bridge connection.
public enum BridgeConnectionState: String, Codable, Equatable {
    case disconnected
    case connecting
    case connected
    case error(BridgeError)

    public var description: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        case .error(let error): return "Error: \(error.localizedDescription)"
        }
    }

    public var color: Color {
        switch self {
        case .disconnected: return .gray
        case .connecting: return .orange
        case .connected: return .green
        case .error: return .red
        }
    }

    // Explicit Codable implementation to handle the associated value in error case
    private enum CodingKeys: String, CodingKey {
        case type, error
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "disconnected": self = .disconnected
        case "connecting": self = .connecting
        case "connected": self = .connected
        case "error":
            let error = try container.decode(BridgeError.self, forKey: .error)
            self = .error(error)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown type")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .disconnected:
            try container.encode("disconnected", forKey: .type)
        case .connecting:
            try container.encode("connecting", forKey: .type)
        case .connected:
            try container.encode("connected", forKey: .type)
        case .error(let error):
            try container.encode("error", forKey: .type)
            try container.encode(error, forKey: .error)
        }
    }
}
