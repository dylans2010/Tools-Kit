import Foundation

enum PayloadType: String, Codable {
    case game
    case ai
}

enum PayloadSubtype: String, Codable {
    // Game Subtypes
    case battleship
    case basketball
    case tapRace

    // AI Subtypes
    case rewrite
    case summarize
    case reply
}

struct MessagePayload: Codable {
    let type: PayloadType
    let subtype: PayloadSubtype
    let data: Data
    let timestamp: Date
    let senderID: String

    init(type: PayloadType, subtype: PayloadSubtype, data: Data, senderID: String = "local") {
        self.type = type
        self.subtype = subtype
        self.data = data
        self.timestamp = Date()
        self.senderID = senderID
    }
}
