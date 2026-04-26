import Foundation

public enum AgentLogLevel: String, Codable {
    case debug, info, warning, error
}

public struct AgentTelemetry: Codable {
    public let event: String
    public let properties: [String: String]
    public let timestamp: Date

    public init(event: String, properties: [String: String] = [:]) {
        self.event = event
        self.properties = properties
        self.timestamp = Date()
    }
}
