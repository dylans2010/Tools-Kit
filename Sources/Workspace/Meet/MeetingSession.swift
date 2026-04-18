import Foundation
import Daily

struct MeetingSession: Identifiable, Equatable, Codable {
    var id: String { sessionId }

    let meetingId: String
    let roomName: String
    let sessionId: String
    let createdAt: Date
    let debugTraceId: String
}
