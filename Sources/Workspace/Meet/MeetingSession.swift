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
}
