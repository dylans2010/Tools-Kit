import Foundation

struct AgentIdentifiers {
    static func sessionID() -> String { UUID().uuidString }
    static func messageID() -> String { UUID().uuidString }
}
