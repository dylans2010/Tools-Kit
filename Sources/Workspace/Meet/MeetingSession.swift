import Foundation

struct MeetingSession: Identifiable, Equatable, Codable, Sendable {
    private static let minimumOpaqueMeetingTokenLength = 24
    private static let base64URLCharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")

    var id: String { sessionId }

    let meetingId: String
    let roomName: String
    /// Indicates whether the user can join the meeting; false means authorization prerequisites failed.
    let isJoinable: Bool
    /// Indicates that Daily room policy requires a meeting token at join time.
    let requiresMeetingToken: Bool
    /// Token returned by backend session resolution for Daily join authorization (typically JWT-like).
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

    enum CodingKeys: String, CodingKey, Sendable {
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

    static func isLikelyValidMeetingToken(_ token: String) -> Bool {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        guard !trimmed.contains(where: { $0.isWhitespace }) else { return false }
        let jwtSegments = trimmed.split(separator: ".")
        if jwtSegments.count == 3 {
            return jwtSegments.allSatisfy { !$0.isEmpty && $0.unicodeScalars.allSatisfy { Self.base64URLCharacterSet.contains($0) } }
        }
        return trimmed.count >= minimumOpaqueMeetingTokenLength
    }
}
