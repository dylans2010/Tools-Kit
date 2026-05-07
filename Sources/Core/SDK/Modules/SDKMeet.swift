import Foundation

/// SDKMeet: Manages virtual meetings and real-time sessions within the WorkspaceSDK.
public final class SDKMeet {
    public static let shared = SDKMeet()

    private let dataStore = SDKDataStore.shared
    private let collection = "meet_sessions"

    public struct Session: SDKModel {
        public let id: UUID
        public let title: String
        public let roomURL: String
        public let startTime: Date
        public var endTime: Date?
        public let createdAt: Date
        public var updatedAt: Date

        public init(id: UUID = UUID(), title: String, roomURL: String, startTime: Date = Date(), createdAt: Date = Date(), updatedAt: Date = Date()) {
            self.id = id
            self.title = title
            self.roomURL = roomURL
            self.startTime = startTime
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    private init() {
        registerEndpoints()
    }

    private func registerEndpoints() {
        SDKRouter.shared.register(endpoint: "meet.start") { request in
            guard let title = request.parameters["title"] as? String else {
                throw SDKMeetError.invalidParameters
            }
            return try await self.startMeeting(title: title)
        }

        SDKRouter.shared.register(endpoint: "meet.list") { _ in
            return try self.listSessions()
        }
    }

    public func startMeeting(title: String) async throws -> Session {
        try SDKPermissionManager.shared.enforce(scope: .meetWrite)

        // Local signaling simulation: generate a mock room URL
        let roomURL = "https://meet.workspace.com/\(UUID().uuidString.prefix(8))"
        let session = Session(title: title, roomURL: roomURL)

        try dataStore.save(session, in: collection)

        SDKEventBus.shared.publish(SDKEvent(type: "meet.started", source: "SDKMeet", payload: ["title": title, "url": roomURL]))
        return session
    }

    public func listSessions() throws -> [Session] {
        try SDKPermissionManager.shared.enforce(scope: .meetRead)
        return try dataStore.fetchAll(in: collection)
    }
}

public enum SDKMeetError: Error {
    case invalidParameters
}
