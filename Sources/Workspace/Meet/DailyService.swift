import Foundation

actor DailyService {
    static let defaultDailyDomain = "toolskit.daily.co"
    static let shared = DailyService()

    enum ServiceError: LocalizedError {
        case invalidMeetingID
        case notFound

        var errorDescription: String? {
            switch self {
            case .invalidMeetingID:
                return "Invalid meeting ID."
            case .notFound:
                return "Meeting ID was not found."
            }
        }
    }

    private struct RoomRecord {
        let session: MeetingSession
        let internalRoomURL: URL
    }

    private var recordsByMeetingID: [String: RoomRecord] = [:]
    private var activeSessions: [String: MeetingSession] = [:]
    private var developerAPIKey: String?

    private let dailyDomain: String

    init(dailyDomain: String = DailyService.defaultDailyDomain) {
        self.dailyDomain = dailyDomain
    }

    func setDeveloperAPIKey(_ value: String) async {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        developerAPIKey = trimmed.isEmpty ? nil : trimmed
        await log("Developer API key updated (in-memory only).", level: .debug)
    }

    func createRoom(for meetingId: String) async throws -> MeetingSession {
        let normalizedID = normalizeMeetingID(meetingId)
        guard !normalizedID.isEmpty else { throw ServiceError.invalidMeetingID }

        if let existing = recordsByMeetingID[normalizedID]?.session {
            await log("Room create reused existing session for \(normalizedID).", level: .warning)
            return existing
        }

        let roomName = "meet-\(normalizedID.lowercased())"
        let session = MeetingSession(
            meetingId: normalizedID,
            roomName: roomName,
            sessionId: UUID().uuidString,
            createdAt: Date(),
            debugTraceId: UUID().uuidString
        )
        var components = URLComponents()
        components.scheme = "https"
        components.host = dailyDomain
        components.path = "/\(roomName)"
        components.queryItems = [URLQueryItem(name: "tk_session", value: session.sessionId)]
        guard let internalURL = components.url else {
            await log("Room URL generation failed for meeting ID \(normalizedID).", level: .error)
            throw ServiceError.invalidMeetingID
        }
        recordsByMeetingID[normalizedID] = RoomRecord(session: session, internalRoomURL: internalURL)

        await log("Room created for meeting ID \(normalizedID). trace=\(session.debugTraceId)", level: .info)
        return session
    }

    func resolveMeetingID(_ meetingId: String) async throws -> MeetingSession {
        let normalizedID = normalizeMeetingID(meetingId)
        guard !normalizedID.isEmpty else { throw ServiceError.invalidMeetingID }

        guard let record = recordsByMeetingID[normalizedID] else {
            await log("Meeting ID resolve failed for \(normalizedID).", level: .error)
            throw ServiceError.notFound
        }

        await log("Meeting ID resolved for \(normalizedID).", level: .info)
        return record.session
    }

    func beginSession(_ session: MeetingSession) async {
        activeSessions[session.sessionId] = session
        await log("Session begin \(session.sessionId).", level: .info)
    }

    func endSession(_ session: MeetingSession) async {
        activeSessions.removeValue(forKey: session.sessionId)
        await log("Session end \(session.sessionId).", level: .info)
    }

    func internalRoomURL(for session: MeetingSession) async -> URL? {
        recordsByMeetingID[session.meetingId]?.internalRoomURL
    }

    func debugSnapshot() async -> DailyDebugSnapshot {
        let mappings = recordsByMeetingID.values
            .map { record in
                DailyDebugMapping(
                    id: record.session.sessionId,
                    meetingId: record.session.meetingId,
                    roomName: record.session.roomName,
                    sessionId: record.session.sessionId,
                    createdAt: record.session.createdAt,
                    debugTraceId: record.session.debugTraceId
                )
            }
            .sorted { $0.createdAt > $1.createdAt }

        let active = activeSessions.values.sorted { $0.createdAt > $1.createdAt }
        return DailyDebugSnapshot(mappings: mappings, activeSessions: active)
    }

    private func normalizeMeetingID(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
    }

    private func log(_ message: String, level: DebugLogLevel) async {
        await MainActor.run {
            DebugLogger.shared.log(message, level: level, category: "DailyService")
        }
    }
}
