import Foundation
import Combine

/// Protocol for the SDK meet service.
@MainActor
public protocol SDKMeetServiceProtocol {
    func createSession(title: String, participants: [String]) throws -> SDKMeetSession
    func listSessions() -> [SDKMeetSession]
}

/// Full SDK Meet module — handles session management, presence, and local signaling.
@MainActor
public final class SDKMeetService: SDKMeetServiceProtocol, ObservableObject {
    nonisolated(unsafe) public static let shared = SDKMeetService()

    @Published public private(set) var sessions: [SDKMeetSession] = []
    @Published public private(set) var activeSession: SDKMeetSession?
    @Published public private(set) var presenceMap: [UUID: [String]] = [:]

    private let dataStore = SDKDataStore.shared

    private init() {}

    public func initialize() {
        loadFromStore()
    }

    // MARK: - Create Session

    public func createSession(title: String, participants: [String] = []) throws -> SDKMeetSession {
        var session = SDKMeetSession(title: title, participants: participants)
        session.status = .scheduled

        try dataStore.save(session)
        sessions.insert(session, at: 0)

        SDKEventBus.shared.publish(SDKBusEvent(channel: "meet", name: "session.created", data: ["id": session.id.uuidString, "title": title]))
        Task { await SDKLogStore.shared.log("Meet session created: \(title)", source: "SDKMeetService", level: .info) }
        return session
    }

    // MARK: - Start/End Session

    public func startSession(id: UUID) async throws {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else {
            throw SDKError.executionFailed(reason: "Session not found")
        }

        // Integrate with Daily.co
        let dailySession = try await DailyService.shared.createRoom(for: sessions[index].title)
        if let roomURL = await DailyService.shared.internalRoomURL(for: dailySession) {
            sessions[index].roomURL = roomURL.absoluteString
        }

        sessions[index].status = .active
        sessions[index].startedAt = Date()
        sessions[index].updatedAt = Date()
        activeSession = sessions[index]
        try dataStore.save(sessions[index])

        presenceMap[id] = sessions[index].participants

        SDKEventBus.shared.publish(SDKBusEvent(channel: "meet", name: "session.started", data: ["id": id.uuidString]))
        await SDKLogStore.shared.log("Meet session started: \(sessions[index].title)", source: "SDKMeetService", level: .info)
    }

    public func endSession(id: UUID) throws {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else {
            throw SDKError.executionFailed(reason: "Session not found")
        }

        sessions[index].status = .ended
        sessions[index].endedAt = Date()
        sessions[index].updatedAt = Date()
        try dataStore.save(sessions[index])

        if activeSession?.id == id { activeSession = nil }
        presenceMap.removeValue(forKey: id)

        SDKEventBus.shared.publish(SDKBusEvent(channel: "meet", name: "session.ended", data: ["id": id.uuidString]))
    }

    // MARK: - Presence

    public func addParticipant(sessionId: UUID, participant: String) throws {
        guard let index = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        if !sessions[index].participants.contains(participant) {
            sessions[index].participants.append(participant)
            sessions[index].updatedAt = Date()
            try dataStore.save(sessions[index])

            if presenceMap[sessionId] == nil { presenceMap[sessionId] = [] }
            presenceMap[sessionId]?.append(participant)

            SDKEventBus.shared.publish(SDKBusEvent(channel: "meet", name: "participant.joined", data: ["sessionId": sessionId.uuidString, "participant": participant]))
        }
    }

    public func removeParticipant(sessionId: UUID, participant: String) throws {
        guard let index = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        sessions[index].participants.removeAll { $0 == participant }
        sessions[index].updatedAt = Date()
        try dataStore.save(sessions[index])

        presenceMap[sessionId]?.removeAll { $0 == participant }

        SDKEventBus.shared.publish(SDKBusEvent(channel: "meet", name: "participant.left", data: ["sessionId": sessionId.uuidString, "participant": participant]))
    }

    // MARK: - Notes

    public func addNotes(sessionId: UUID, notes: String) throws {
        guard let index = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        sessions[index].notes = notes
        sessions[index].updatedAt = Date()
        try dataStore.save(sessions[index])
    }

    // MARK: - Read

    public func listSessions() -> [SDKMeetSession] {
        return sessions
    }

    public func getSession(id: UUID) -> SDKMeetSession? {
        return sessions.first { $0.id == id }
    }

    public func activeSessions() -> [SDKMeetSession] {
        return sessions.filter { $0.status == .active }
    }

    // MARK: - Delete

    public func deleteSession(id: UUID) throws {
        try dataStore.delete(SDKMeetSession.self, id: id)
        sessions.removeAll { $0.id == id }
        if activeSession?.id == id { activeSession = nil }
        presenceMap.removeValue(forKey: id)
        SDKEventBus.shared.publish(SDKBusEvent(channel: "meet", name: "session.deleted", data: ["id": id.uuidString]))
    }

    // MARK: - Private

    private func loadFromStore() {
        sessions = dataStore.fetchAll(SDKMeetSession.self)
    }
}
