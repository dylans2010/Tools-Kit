import Foundation

/// Unified event model for the SDK event bus.
public struct SDKBusEvent: Identifiable, Codable {
    public let id: UUID
    public let channel: String
    public let name: String
    public let data: [String: String]
    public let source: String
    public let timestamp: Date
    public let priority: Priority

    public enum Priority: Int, Codable {
        case low = 0
        case normal = 1
        case high = 2
        case critical = 3
    }

    public init(
        channel: String,
        name: String,
        data: [String: String] = [:],
        source: String = "SDK",
        priority: Priority = .normal
    ) {
        self.id = UUID()
        self.channel = channel
        self.name = name
        self.data = data
        self.source = source
        self.timestamp = Date()
        self.priority = priority
    }
}
