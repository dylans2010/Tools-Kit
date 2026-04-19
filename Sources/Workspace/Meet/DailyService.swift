import Foundation

actor DailyService {
    static let dailyAPIBaseURL = URL(string: "https://api.daily.co/v1")!
    static let apiRequestTimeoutInterval: TimeInterval = 20
    static let dailyTokenParameterName = "t"
    static let persistedAPIKeyStorageKey = "daily_api_key"
    static let shared = DailyService()

    enum ServiceError: LocalizedError {
        case invalidMeetingID
        case missingAPIKey
        case notFound
        case invalidResponse
        case requestFailed(statusCode: Int, message: String?)
        case networkFailure(underlying: Error)

        var errorDescription: String? {
            switch self {
            case .invalidMeetingID:
                return "Invalid meeting ID."
            case .missingAPIKey:
                return "Daily API key is required."
            case .notFound:
                return "Meeting ID was not found."
            case .invalidResponse:
                return "Daily API returned an invalid response."
            case let .requestFailed(statusCode, message):
                return message ?? "Daily API request failed with status \(statusCode)."
            case let .networkFailure(underlying):
                return "Network request failed: \(underlying.localizedDescription)"
            }
        }
    }

    private struct RoomRecord {
        let session: MeetingSession
        let roomURL: URL
    }

    private struct RoomResponse: Decodable {
        let name: String
        let url: String
        let privacy: String?
    }

    private struct MeetingTokenResponse: Decodable {
        let token: String
    }

    private struct ErrorResponse: Decodable {
        let info: String?
        let error: String?
    }

    private var recordsByMeetingID: [String: RoomRecord] = [:]
    private var activeSessions: [String: MeetingSession] = [:]
    private var breakoutRoomsBySession: [String: [MeetingBreakoutRoom]] = [:]
    private var participantRolesBySession: [String: [String: MeetingParticipantRole]] = [:]

    func createRoom(for meetingId: String?) async throws -> MeetingSession {
        let trimmedID = meetingId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if trimmedID.isEmpty {
            let room = try await createGeneratedRoom()
            let normalizedGeneratedID = normalizeMeetingID(room.name)
            guard !normalizedGeneratedID.isEmpty else { throw ServiceError.invalidMeetingID }
            let session = try await storeRoom(room, meetingID: normalizedGeneratedID)
            await log("Room created with Daily-generated meeting ID \(session.meetingId). trace=\(session.debugTraceId)", level: .info)
            return session
        }

        let normalizedID = normalizeMeetingID(trimmedID)
        guard !normalizedID.isEmpty else { throw ServiceError.invalidMeetingID }

        if let existing = recordsByMeetingID[normalizedID]?.session {
            await log("Room create reused existing session for \(normalizedID).", level: .warning)
            return existing
        }

        let room = try await createOrFetchRoom(named: roomName(for: normalizedID))
        let session = try await storeRoom(room, meetingID: normalizedID)
        await log("Room created for meeting ID \(normalizedID). trace=\(session.debugTraceId)", level: .info)
        return session
    }

    func generateMeetingID() async throws -> String {
        // Daily generates IDs by creating a room. We intentionally cache the resulting
        // session so a later create call with this ID reuses it instead of provisioning again.
        let session = try await createRoom(for: nil)
        return session.meetingId
    }

    func resolveMeetingID(_ meetingId: String) async throws -> MeetingSession {
        let normalizedID = normalizeMeetingID(meetingId)
        guard !normalizedID.isEmpty else { throw ServiceError.invalidMeetingID }

        if let record = recordsByMeetingID[normalizedID] {
            await log("Meeting ID resolved for \(normalizedID).", level: .info)
            return record.session
        }

        guard let room = try await fetchRoomForMeetingID(normalizedID) else {
            await log("Meeting ID resolve failed for \(normalizedID).", level: .error)
            throw ServiceError.notFound
        }
        let session = try await storeRoom(room, meetingID: normalizedID)

        await log("Meeting ID resolved for \(normalizedID).", level: .info)
        return session
    }

    func beginSession(_ session: MeetingSession) async {
        activeSessions[session.sessionId] = session
        await log("Session begin \(session.sessionId).", level: .info)
    }

    func endSession(_ session: MeetingSession) async {
        activeSessions.removeValue(forKey: session.sessionId)
        await log("Session end \(session.sessionId).", level: .info)
    }

    func applyAdminAction(_ action: MeetingAdminAction, in session: MeetingSession) async {
        var roles = participantRolesBySession[session.sessionId] ?? [:]
        switch action {
        case .muteAll:
            await log("Admin action: mute all in session \(session.sessionId).", level: .info)
        case let .setParticipantMuted(participantId, muted):
            await log("Admin action: set muted=\(muted) for \(participantId).", level: .info)
        case let .setParticipantVideoEnabled(participantId, enabled):
            await log("Admin action: set video enabled=\(enabled) for \(participantId).", level: .info)
        case let .removeParticipant(participantId):
            roles.removeValue(forKey: participantId)
            await log("Admin action: removed participant \(participantId).", level: .warning)
        case let .assignRole(participantId, role):
            roles[participantId] = role
            await log("Admin action: assigned role \(role.rawValue) to \(participantId).", level: .info)
        }
        participantRolesBySession[session.sessionId] = roles
    }

    func updateBreakoutRooms(_ rooms: [MeetingBreakoutRoom], in session: MeetingSession) async {
        breakoutRoomsBySession[session.sessionId] = rooms
        await log("Breakout rooms updated for session \(session.sessionId).", level: .info)
    }

    func internalRoomURL(for session: MeetingSession) async -> URL? {
        recordsByMeetingID[session.meetingId]?.roomURL
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

    private func roomName(for meetingID: String) -> String {
        // Deterministic Meeting ID -> Daily room mapping to keep ID-only join flow.
        "meet-\(meetingID.lowercased())"
    }

    private func roomNameCandidates(for meetingID: String) -> [String] {
        let deterministicRoomName = roomName(for: meetingID)
        let directRoomName = meetingID.lowercased()
        // Try direct room names first because Daily-generated IDs map directly to room names.
        // Keep deterministic prefixed names as fallback for meetings created before we switched
        // from local prefixed IDs to Daily-generated IDs.
        var candidates = [directRoomName]
        if deterministicRoomName != directRoomName {
            candidates.append(deterministicRoomName)
        }
        return candidates
    }

    private func fetchRoomForMeetingID(_ meetingID: String) async throws -> RoomResponse? {
        for candidate in roomNameCandidates(for: meetingID) {
            if let room = try await fetchRoom(named: candidate) {
                return room
            }
        }
        return nil
    }

    private func createOrFetchRoom(named roomName: String) async throws -> RoomResponse {
        let payload: [String: Any] = [
            "name": roomName,
            "privacy": "private"
        ]

        let result = try await performDailyRequest(method: "POST", path: "rooms", body: payload)

        switch result.statusCode {
        case 200, 201:
            return try decodeRoom(from: result.data)
        case 409:
            guard let existing = try await fetchRoom(named: roomName) else {
                throw ServiceError.notFound
            }
            return existing
        default:
            throw try mapFailure(statusCode: result.statusCode, data: result.data)
        }
    }

    private func createGeneratedRoom() async throws -> RoomResponse {
        let payload: [String: Any] = [
            "privacy": "private"
        ]
        let result = try await performDailyRequest(method: "POST", path: "rooms", body: payload)
        switch result.statusCode {
        case 200, 201:
            return try decodeRoom(from: result.data)
        default:
            throw try mapFailure(statusCode: result.statusCode, data: result.data)
        }
    }

    private func fetchRoom(named roomName: String) async throws -> RoomResponse? {
        let encodedName = roomName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? roomName
        let result = try await performDailyRequest(method: "GET", path: "rooms/\(encodedName)", body: nil)

        switch result.statusCode {
        case 200:
            return try decodeRoom(from: result.data)
        case 404:
            return nil
        default:
            throw try mapFailure(statusCode: result.statusCode, data: result.data)
        }
    }

    private func storeRoom(_ room: RoomResponse, meetingID: String) async throws -> MeetingSession {
        // Defensive dedupe for concurrent create/resolve calls that target the same meeting ID.
        if let existing = recordsByMeetingID[meetingID]?.session {
            return existing
        }

        let roomURL = try await validatedRoomURL(from: room.url, roomName: room.name)
        let requiresMeetingToken = roomRequiresMeetingToken(room)
        var meetingToken: String?
        var isJoinable = true

        if requiresMeetingToken {
            do {
                let token = try await createMeetingToken(for: room.name)
                let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedToken.isEmpty {
                    // Keep session resolution successful but mark not joinable so UI can show a friendly
                    // authorization error without attempting Daily join.
                    isJoinable = false
                    await log("Meeting token generation returned an empty token for room \(room.name); session will be marked not joinable.", level: .error)
                } else {
                    meetingToken = trimmedToken
                }
            } catch let error as ServiceError {
                if case let .requestFailed(statusCode, _) = error, statusCode == 401 || statusCode == 403 {
                    // Convert authorization failures into non-joinable state so join is blocked in pre-validation,
                    // while preserving resolver success and avoiding runtime join crashes.
                    isJoinable = false
                    await log("Meeting token generation unauthorized for room \(room.name). status=\(statusCode). Session marked not joinable for UI-safe handling.", level: .error)
                } else {
                    throw error
                }
            }
        }

        let session = MeetingSession(
            meetingId: meetingID,
            roomName: room.name,
            isJoinable: isJoinable,
            requiresMeetingToken: requiresMeetingToken,
            meetingToken: meetingToken,
            sessionId: UUID().uuidString,
            createdAt: Date(),
            debugTraceId: UUID().uuidString
        )
        recordsByMeetingID[meetingID] = RoomRecord(session: session, roomURL: roomURL)
        return session
    }

    private func performDailyRequest(
        method: String,
        path: String,
        body: [String: Any]?
    ) async throws -> (data: Data, statusCode: Int) {
        let apiKey = try await resolvedAPIKey()

        let url = buildAPIURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = DailyService.apiRequestTimeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ServiceError.invalidResponse
            }
            return (data, httpResponse.statusCode)
        } catch let error as ServiceError {
            throw error
        } catch {
            throw ServiceError.networkFailure(underlying: error as! Error)
        }
    }

    private func decodeRoom(from data: Data) throws -> RoomResponse {
        do {
            return try JSONDecoder().decode(RoomResponse.self, from: data)
        } catch {
            throw ServiceError.invalidResponse
        }
    }

    private func mapFailure(statusCode: Int, data: Data) throws -> ServiceError {
        let details = try? JSONDecoder().decode(ErrorResponse.self, from: data)
        let message = details?.error ?? details?.info
        return .requestFailed(statusCode: statusCode, message: message)
    }

    private func createMeetingToken(for roomName: String) async throws -> String {
        let payload: [String: Any] = [
            "properties": [
                "room_name": roomName
            ]
        ]

        let result = try await performDailyRequest(method: "POST", path: "meeting-tokens", body: payload)
        switch result.statusCode {
        case 200, 201:
            do {
                return try JSONDecoder().decode(MeetingTokenResponse.self, from: result.data).token
            } catch {
                throw ServiceError.invalidResponse
            }
        default:
            throw try mapFailure(statusCode: result.statusCode, data: result.data)
        }
    }

    private func validatedRoomURL(from value: String, roomName: String) async throws -> URL {
        guard let roomURL = URL(string: value) else {
            await log("Daily returned invalid room URL for \(roomName).", level: .error)
            throw ServiceError.invalidResponse
        }
        return roomURL
    }

    private func roomRequiresMeetingToken(_ room: RoomResponse) -> Bool {
        guard let privacy = room.privacy?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !privacy.isEmpty else {
            // Default to secure/private expectations when privacy is not returned.
            return true
        }
        return privacy != "public"
    }

    private func buildAPIURL(path: String) -> URL {
        DailyService.dailyAPIBaseURL.appendingPathComponent(path)
    }

    private func resolvedAPIKey() async throws -> String {
        let persistedValue = UserDefaults.standard.string(forKey: DailyService.persistedAPIKeyStorageKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !persistedValue.isEmpty {
            return persistedValue
        }
        await log("Missing Daily API key in persistent storage key '\(DailyService.persistedAPIKeyStorageKey)'.", level: .error)
        throw ServiceError.missingAPIKey
    }

    private func log(_ message: String, level: DebugLogLevel) async {
        await MainActor.run {
            DebugLogger.shared.log(message, level: level, category: "DailyService")
        }
    }
}
