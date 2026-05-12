import Foundation

struct AgentIdentifiers: Sendable {
    static func sessionID() -> String { UUID().uuidString }
    static func messageID() -> String { UUID().uuidString }
}
