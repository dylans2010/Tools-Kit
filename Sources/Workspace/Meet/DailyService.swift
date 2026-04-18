import Foundation
import Daily

actor DailyService {
    static let dailyAPIBaseURL = URL(string: "https://api.daily.co/v1")!
    static let apiRequestTimeoutInterval: TimeInterval = 20
    static let dailyTokenParameterName = "t"
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
    private var developerAPIKey: String?

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

        let roomName = roomName(for: normalizedID)
        let room = try await createOrFetchRoom(named: roomName)
        let roomURL = try await securedRoomURL(from: room)

        let session = MeetingSession(
            meetingId: normalizedID,
            roomName: roomName,
            sessionId: UUID().uuidString,
            createdAt: Date(),
            debugTraceId: UUID().uuidString
        )
        recordsByMeetingID[normalizedID] = RoomRecord(session: session, roomURL: roomURL)

        await log("Room created for meeting ID \(normalizedID). trace=\(session.debugTraceId)", level: .info)
        return session
    }

    func resolveMeetingID(_ meetingId: String) async throws -> MeetingSession {
        let normalizedID = normalizeMeetingID(meetingId)
        guard !normalizedID.isEmpty else { throw ServiceError.invalidMeetingID }

        if let record = recordsByMeetingID[normalizedID] {
            await log("Meeting ID resolved for \(normalizedID).", level: .info)
            return record.session
        }

        let roomName = roomName(for: normalizedID)
        guard let room = try await fetchRoom(named: roomName) else {
            await log("Meeting ID resolve failed for \(normalizedID).", level: .error)
            throw ServiceError.notFound
        }
        let roomURL = try await securedRoomURL(from: room)

        let session = MeetingSession(
            meetingId: normalizedID,
            roomName: room.name,
            sessionId: UUID().uuidString,
            createdAt: Date(),
            debugTraceId: UUID().uuidString
        )
        recordsByMeetingID[normalizedID] = RoomRecord(session: session, roomURL: roomURL)

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

    private func performDailyRequest(
        method: String,
        path: String,
        body: [String: Any]?
    ) async throws -> (data: Data, statusCode: Int) {
        guard let apiKey = developerAPIKey else {
            throw ServiceError.missingAPIKey
        }

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

    private func securedRoomURL(from room: RoomResponse) async throws -> URL {
        let baseURL = try await validatedRoomURL(from: room.url, roomName: room.name)
        let token = try await createMeetingToken(for: room.name)
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw ServiceError.invalidResponse
        }
        var queryItems = components.queryItems ?? []
        // Avoid duplicate token query items when regenerating secured URLs.
        queryItems.removeAll(where: { $0.name == DailyService.dailyTokenParameterName })
        queryItems.append(URLQueryItem(name: DailyService.dailyTokenParameterName, value: token))
        components.queryItems = queryItems
        guard let securedURL = components.url else {
            throw ServiceError.invalidResponse
        }
        return securedURL
    }

    private func buildAPIURL(path: String) -> URL {
        DailyService.dailyAPIBaseURL.appendingPathComponent(path)
    }

    private func log(_ message: String, level: DebugLogLevel) async {
        await MainActor.run {
            DebugLogger.shared.log(message, level: level, category: "DailyService")
        }
    }
}
