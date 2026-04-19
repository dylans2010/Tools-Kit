import Foundation

struct MeetingSession: Identifiable, Equatable, Codable {
    var id: String { sessionId }

    let meetingId: String
    let roomName: String
    let isJoinable: Bool
    let requiresMeetingToken: Bool
    let meetingToken: String?
    let sessionId: String
    let createdAt: Date
    let debugTraceId: String

    init(
        meetingId: String,
        roomName: String,
        isJoinable: Bool = true,
        requiresMeetingToken: Bool = false,
        meetingToken: String? = nil,
        sessionId: String,
        createdAt: Date,
        debugTraceId: String
    ) {
        self.meetingId = meetingId
        self.roomName = roomName
        self.isJoinable = isJoinable
        self.requiresMeetingToken = requiresMeetingToken
        self.meetingToken = meetingToken
        self.sessionId = sessionId
        self.createdAt = createdAt
        self.debugTraceId = debugTraceId
    }

    enum CodingKeys: String, CodingKey {
        case meetingId
        case roomName
        case isJoinable
        case requiresMeetingToken
        case meetingToken
        case sessionId
        case createdAt
        case debugTraceId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.meetingId = try container.decode(String.self, forKey: .meetingId)
        self.roomName = try container.decode(String.self, forKey: .roomName)
        self.isJoinable = try container.decodeIfPresent(Bool.self, forKey: .isJoinable) ?? true
        self.requiresMeetingToken = try container.decodeIfPresent(Bool.self, forKey: .requiresMeetingToken) ?? false
        self.meetingToken = try container.decodeIfPresent(String.self, forKey: .meetingToken)
        self.sessionId = try container.decode(String.self, forKey: .sessionId)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.debugTraceId = try container.decode(String.self, forKey: .debugTraceId)
    }
}
