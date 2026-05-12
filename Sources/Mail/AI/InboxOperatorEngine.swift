import Foundation

/// Autonomous engine for inbox triage, cleanup, and batch execution with constraints.
actor InboxOperatorEngine {
    nonisolated(unsafe) static let shared = InboxOperatorEngine()
    private let aiService = AIService.shared
    private let mailAIService = MailAIService.shared

    private init() {}

    /// Triage a set of threads and return execution plans for each.
    func performTriage(on threads: [MailThread]) async throws -> [UUID: String] {
        var decisions: [UUID: String] = [:]
        for thread in threads {
            let intent = try? await CommunicationIntelligenceEngine.shared.classifyIntent(for: thread)
            let summary = try? await mailAIService.summarizeThread(thread)
            let explanation = "Classified as \(intent?.rawValue ?? "unknown"). \(summary ?? "")"
            decisions[UUID()] = explanation
        }
        return decisions
    }

    /// Executes a batch of actions on threads.
    func executeBatchActions(actions: [BatchAction], account: MailAccount) async throws {
        for action in actions {
            switch action.type {
            case .archive:
                try await MailIMAPService.shared.archiveMessage(messageID: action.threadID, account: account)
            case .star:
                try await MailIMAPService.shared.setFlag(messageID: action.threadID, flag: "\\Starred", account: account)
            case .markRead:
                try await MailIMAPService.shared.markAsRead(messageID: action.threadID, account: account)
            case .delete:
                try await MailIMAPService.shared.deleteMessage(messageID: action.threadID, account: account)
            default:
                WorkspaceLogger.general.info("InboxOperator action \(String(describing: action.type)) not yet implemented for IMAP.")
            }
        }
    }

    struct BatchAction: Codable, Sendable {
        let threadID: String
        let type: ActionType
        enum ActionType: String, Codable, Sendable {
            case archive, star, label, delete, markRead
        }
    }
}
