import Foundation
import Appwrite
import UIKit

enum FeedbackServiceError: LocalizedError {
    case missingConfig
    case invalidCurrentUser

    var errorDescription: String? {
        switch self {
        case .missingConfig:
            return "Missing feedback Appwrite configuration in Config.plist"
        case .invalidCurrentUser:
            return "Please sign in to view your feedback history."
        }
    }
}

final class FeedbackService {
    static let shared = FeedbackService()

    private let databases = Databases(AppwriteService.client)
    private let account = AppwriteService.account

    private let databaseId: String?
    private let collectionId: String?

    private init() {
        self.databaseId = Self.configValue(forKey: "APPWRITE_FEEDBACK_DATABASE_ID")
        self.collectionId = Self.configValue(forKey: "APPWRITE_FEEDBACK_COLLECTION_ID")
    }

    func submitFeedback(message: String, category: FeedbackCategory, userCanViewStatus: Bool = false) async throws -> Feedback {
        guard let databaseId, let collectionId else {
            throw FeedbackServiceError.missingConfig
        }

        let now = Date()
        let isoNow = Self.isoFormatter.string(from: now)
        let user = try? await account.get()

        let userName = [user?.name, user?.email]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty }) ?? "Anonymous"

        let payload: [String: Any] = [
            "userId": user?.id ?? "",
            "userName": userName,
            "message": message,
            "category": category.rawValue,
            "createdAt": isoNow,
            "device": Self.deviceDescriptor(),
            "appVersion": Self.appVersionString(),
            "status": FeedbackStatus.open.rawValue,
            "priority": FeedbackPriority.medium.rawValue,
            "internalNotes": "",
            "lastUpdatedAt": isoNow,
            "assignedTo": "",
            "userCanViewStatus": userCanViewStatus
        ]

        let document = try await databases.createDocument(
            databaseId: databaseId,
            collectionId: collectionId,
            documentId: ID.unique(),
            data: payload,
            nestedType: FeedbackDocumentData.self
        )

        return feedback(from: document)
    }

    func fetchAllFeedback(
        category: FeedbackCategory? = nil,
        status: FeedbackStatus? = nil,
        priority: FeedbackPriority? = nil
    ) async throws -> [Feedback] {
        guard let databaseId, let collectionId else {
            throw FeedbackServiceError.missingConfig
        }

        var queries: [String] = [Query.orderDesc("createdAt"), Query.limit(Self.maxFeedbackLimit)]

        if let category {
            queries.append(Query.equal("category", value: category.rawValue))
        }

        if let status {
            queries.append(Query.equal("status", value: status.rawValue))
        }

        if let priority {
            queries.append(Query.equal("priority", value: priority.rawValue))
        }

        let response = try await databases.listDocuments(
            databaseId: databaseId,
            collectionId: collectionId,
            queries: queries,
            nestedType: FeedbackDocumentData.self
        )

        return response.documents.map(feedback(from:))
    }

    func fetchMyFeedback() async throws -> [Feedback] {
        guard let databaseId, let collectionId else {
            throw FeedbackServiceError.missingConfig
        }

        let currentUser = try await account.get()

        let response = try await databases.listDocuments(
            databaseId: databaseId,
            collectionId: collectionId,
            queries: [
                Query.equal("userId", value: currentUser.id),
                Query.equal("userCanViewStatus", value: true),
                Query.orderDesc("createdAt"),
                Query.limit(Self.maxFeedbackLimit)
            ],
            nestedType: FeedbackDocumentData.self
        )

        return response.documents.map(feedback(from:))
    }

    func updateStatus(feedbackId: String, status: FeedbackStatus) async throws {
        try await updateFeedback(feedbackId: feedbackId, data: [
            "status": status.rawValue,
            "lastUpdatedAt": Self.isoFormatter.string(from: Date())
        ])
    }

    func updatePriority(feedbackId: String, priority: FeedbackPriority) async throws {
        try await updateFeedback(feedbackId: feedbackId, data: [
            "priority": priority.rawValue,
            "lastUpdatedAt": Self.isoFormatter.string(from: Date())
        ])
    }

    func updateNotes(feedbackId: String, notes: String) async throws {
        try await updateFeedback(feedbackId: feedbackId, data: [
            "internalNotes": notes,
            "lastUpdatedAt": Self.isoFormatter.string(from: Date())
        ])
    }

    func assignFeedback(feedbackId: String, assignee: String?) async throws {
        try await updateFeedback(feedbackId: feedbackId, data: [
            "assignedTo": (assignee ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            "lastUpdatedAt": Self.isoFormatter.string(from: Date())
        ])
    }

    private func updateFeedback(feedbackId: String, data: [String: Any]) async throws {
        guard let databaseId, let collectionId else {
            throw FeedbackServiceError.missingConfig
        }

        _ = try await databases.updateDocument(
            databaseId: databaseId,
            collectionId: collectionId,
            documentId: feedbackId,
            data: data,
            nestedType: FeedbackDocumentData.self
        )
    }

    private func feedback(from document: Document<FeedbackDocumentData>) -> Feedback {
        let data = document.data
        return Feedback(
            id: document.id,
            userId: data.userId?.nilIfBlank,
            userName: data.userName,
            message: data.message,
            category: data.category,
            createdAt: Self.parseDate(data.createdAt),
            device: data.device,
            appVersion: data.appVersion,
            status: data.status,
            priority: data.priority,
            internalNotes: data.internalNotes,
            lastUpdatedAt: data.lastUpdatedAt.flatMap(Self.parseDate),
            assignedTo: data.assignedTo?.nilIfBlank,
            userCanViewStatus: data.userCanViewStatus
        )
    }

    private static func parseDate(_ value: String) -> Date {
        if let date = isoFormatter.date(from: value) { return date }
        return fallbackISOFormatter.date(from: value) ?? .distantPast
    }

    private static func appVersionString() -> String {
        let bundle = Bundle.main
        let shortVersion = (bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let buildVersion = (bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

        switch (shortVersion?.isEmpty == false ? shortVersion : nil, buildVersion?.isEmpty == false ? buildVersion : nil) {
        case let (short?, build?): return "\(short) (\(build))"
        case let (short?, nil): return short
        case let (nil, build?): return build
        default: return "Unknown"
        }
    }

    private static func deviceDescriptor() -> String {
        let identifier = modelIdentifier()
        let osVersion = UIDevice.current.systemVersion
        return "\(identifier) (iOS \(osVersion))"
    }

    private static func modelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { ptr in
                String(cString: ptr)
            }
        }
    }

    private static func configValue(forKey key: String) -> String? {
        guard
            let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let value = plist[key] as? String,
            !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        return value
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let fallbackISOFormatter: ISO8601DateFormatter = {
        ISO8601DateFormatter()
    }()

    private static let maxFeedbackLimit = 200
}

private struct FeedbackDocumentData: Codable {
    let userId: String?
    let userName: String
    let message: String
    let category: String
    let createdAt: String
    let device: String
    let appVersion: String
    let status: String
    let priority: String
    let internalNotes: String
    let lastUpdatedAt: String?
    let assignedTo: String?
    let userCanViewStatus: Bool
}

private extension Optional where Wrapped == String {
    var nilIfBlank: String? {
        guard let self else { return nil }
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
