import Foundation
import Daily

actor MeetingResolver {
    static let shared = MeetingResolver()

    private let dailyService: DailyService

    init(dailyService: DailyService = .shared) {
        self.dailyService = dailyService
    }

    func createSession(with meetingId: String?) async throws -> MeetingSession {
        let logMeetingID: String
        if let meetingId, !meetingId.isEmpty {
            logMeetingID = meetingId
        } else {
            logMeetingID = "<generated-by-daily>"
        }
        await log("Create session attempt for meeting ID \(logMeetingID).", level: .info)
        let session = try await dailyService.createRoom(for: meetingId)
        await log("Create session success for \(session.meetingId).", level: .info)
        return session
    }

    func generateMeetingID() async throws -> String {
        await log("Generate meeting ID using Daily API.", level: .info)
        let generatedID = try await dailyService.generateMeetingID()
        await log("Generated Daily meeting ID \(generatedID).", level: .info)
        return generatedID
    }

    func joinSession(with meetingId: String) async throws -> MeetingSession {
        await log("Join attempt for meeting ID \(meetingId).", level: .info)
        let session = try await dailyService.resolveMeetingID(meetingId)
        await log("Join success for \(session.meetingId).", level: .info)
        return session
    }

    func beginSession(_ session: MeetingSession) async {
        await dailyService.beginSession(session)
    }

    func endSession(_ session: MeetingSession) async {
        await dailyService.endSession(session)
    }

    func internalRoomURL(for session: MeetingSession) async -> URL? {
        await dailyService.internalRoomURL(for: session)
    }

    func updateDeveloperAPIKey(_ value: String) async {
        await dailyService.setDeveloperAPIKey(value)
    }

    func fetchDebugSnapshot() async -> DailyDebugSnapshot {
        await dailyService.debugSnapshot()
    }

    private func log(_ message: String, level: DebugLogLevel) async {
        await MainActor.run {
            DebugLogger.shared.log(message, level: level, category: "MeetingResolver")
        }
    }
}
