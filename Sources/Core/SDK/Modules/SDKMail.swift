import Foundation

/// SDKMail: Handles mail operations within the WorkspaceSDK.
public final class SDKMail {
    public static let shared = SDKMail()

    private let dataStore = SDKDataStore.shared
    private let collection = "mail_messages"

    public struct Message: SDKModel {
        public let id: UUID
        public let threadId: String
        public let from: String
        public let to: [String]
        public let subject: String
        public let body: String
        public let createdAt: Date
        public var updatedAt: Date

        public init(id: UUID = UUID(), threadId: String = UUID().uuidString, from: String, to: [String], subject: String, body: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
            self.id = id
            self.threadId = threadId
            self.from = from
            self.to = to
            self.subject = subject
            self.body = body
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    private init() {
        registerEndpoints()
    }

    private func registerEndpoints() {
        SDKRouter.shared.register(endpoint: "mail.send") { request in
            guard let to = request.parameters["to"] as? String,
                  let subject = request.parameters["subject"] as? String,
                  let body = request.parameters["body"] as? String else {
                throw SDKMailError.invalidParameters
            }
            return try await self.sendMail(to: to, subject: subject, body: body)
        }

        SDKRouter.shared.register(endpoint: "mail.list") { _ in
            return try self.listMessages()
        }
    }

    public func sendMail(to: String, subject: String, body: String) async throws -> Message {
        try SDKPermissionManager.shared.enforce(scope: .mailWrite)

        let message = Message(from: "me@workspace.com", to: [to], subject: subject, body: body)
        try dataStore.save(message, in: collection)

        SDKEventBus.shared.publish(SDKEvent(type: "mail.sent", source: "SDKMail", payload: ["to": to, "subject": subject]))
        return message
    }

    public func listMessages() throws -> [Message] {
        try SDKPermissionManager.shared.enforce(scope: .mailRead)
        return try dataStore.fetchAll(in: collection)
    }
}

public enum SDKMailError: Error {
    case invalidParameters
}
