import Foundation

struct AgentTelemetry: Codable {
    let event: String
    let properties: [String: String]
    let timestamp: Date

    init(event: String, properties: [String: String] = [:]) {
        self.event = event
        self.properties = properties
        self.timestamp = Date()
    }
}
