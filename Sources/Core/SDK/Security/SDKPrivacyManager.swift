import Foundation

@MainActor
public final class SDKPrivacyManager: ObservableObject {
    nonisolated(unsafe) public static let shared = SDKPrivacyManager()

    public struct ExposureLog: Identifiable, Codable, Sendable {
        public let id: UUID
        public let timestamp: Date
        public let scope: String
        public let categories: [String]
        public let redactedFields: [String]
        public let violation: String?
        public let projectID: UUID?
    }

    public struct PrivacyPolicy: Codable, Sendable {
        public let requiredNote: Bool
        public let restrictedFields: Set<String>
        public let retentionDays: Int
    }

    @Published public private(set) var exposureLogs: [ExposureLog] = []

    private var policies: [String: PrivacyPolicy] = [
        "sdk.fetchData.full": PrivacyPolicy(requiredNote: true, restrictedFields: ["token", "password", "secret", "apiKey"], retentionDays: 30),
        "external.api.unrestricted": PrivacyPolicy(requiredNote: true, restrictedFields: ["authorization", "cookie", "set-cookie"], retentionDays: 30),
        "workspace.modify.bulk": PrivacyPolicy(requiredNote: false, restrictedFields: ["privateNotes"], retentionDays: 14)
    ]

    private init() {}

    public func policy(for scope: String) -> PrivacyPolicy {
        policies[scope] ?? PrivacyPolicy(requiredNote: false, restrictedFields: [], retentionDays: 7)
    }

    public func validatePrivacyNote(scope: String, note: String?) throws {
        let policy = policy(for: scope)
        if policy.requiredNote && (note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) {
            throw SDKError.validationError(reason: "Privacy note required for scope: \(scope)")
        }
    }

    public func redactRestrictedFields(_ payload: [String: Any], scope: String) -> [String: Any] {
        let restricted = policy(for: scope).restrictedFields
        var redacted: [String: Any] = [:]
        var fields: [String] = []
        for (key, value) in payload {
            if restricted.contains(key.lowercased()) {
                redacted[key] = "[REDACTED]"
                fields.append(key)
            } else {
                redacted[key] = value
            }
        }
        if !fields.isEmpty {
            logExposure(scope: scope, categories: [], redactedFields: fields, violation: nil, projectID: nil)
        }
        return redacted
    }

    public func logExposure(scope: String, categories: [String], redactedFields: [String], violation: String?, projectID: UUID?) {
        let log = ExposureLog(
            id: UUID(),
            timestamp: Date(),
            scope: scope,
            categories: categories,
            redactedFields: redactedFields,
            violation: violation,
            projectID: projectID
        )
        exposureLogs.insert(log, at: 0)
        enforceRetention(scope: scope)
    }

    public func enforceRetention(scope: String) {
        let maxAge = TimeInterval(policy(for: scope).retentionDays * 86_400)
        let cutoff = Date().addingTimeInterval(-maxAge)
        exposureLogs.removeAll { $0.scope == scope && $0.timestamp < cutoff }
        if exposureLogs.count > 2000 {
            exposureLogs = Array(exposureLogs.prefix(2000))
        }
    }
}
