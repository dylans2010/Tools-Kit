import Foundation

/// Handles automated email workflows based on user-defined rules.
final class MailAutomationEngine {
    nonisolated(unsafe) static let shared = MailAutomationEngine()

    struct AutomationRule: Codable, Identifiable, Sendable {
        let id: UUID
        var name: String
        var triggers: [Trigger]
        var conditions: [Condition]
        var actions: [AutomationAction]
        var isEnabled: Bool
    }

    enum Trigger: Codable, Equatable, Sendable {
        case onNewEmail
        case onThreadUpdate
        case scheduled(TimeInterval)
    }

    enum Condition: Codable, Sendable {
        case senderContains(String)
        case subjectContains(String)
        case bodyContains(String)
        case intentIs(String)
        case priorityAbove(Double)
    }

    enum AutomationAction: Codable, Sendable {
        case archive
        case markAsRead
        case moveToFolder(String)
        case notify(String)
        case generateReply(String)
        case createCalendarEvent
    }

    private var rules: [AutomationRule] = []
    private let mailAIService = MailAIService.shared
    private let executionBridge = ExecutionBridge.shared

    private var rulesURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("automation_rules.json")
    }

    private init() {
        loadRules()
    }

    func processThread(_ thread: MailThread, trigger: Trigger) async {
        for rule in rules where rule.isEnabled && rule.triggers.contains(where: { $0 == trigger }) {
            if await evaluateConditions(rule.conditions, for: thread) {
                await executeActions(rule.actions, for: thread)
            }
        }
    }

    private func evaluateConditions(_ conditions: [Condition], for thread: MailThread) async -> Bool {
        for condition in conditions {
            switch condition {
            case .senderContains(let string):
                if !thread.participants.contains(where: { $0.contains(string) }) { return false }
            case .subjectContains(let string):
                if !thread.subject.contains(string) { return false }
            case .bodyContains(let string):
                if !thread.snippet.contains(string) { return false }
            case .intentIs(let intent):
                let detectedIntent = try? await mailAIService.classifyIntent(for: thread)
                if detectedIntent != intent { return false }
            case .priorityAbove(let score):
                if (thread.priorityScore ?? 0) <= score { return false }
            }
        }
        return true
    }

    private func executeActions(_ actions: [AutomationAction], for thread: MailThread) async {
        for action in actions {
            switch action {
            case .archive:
                WorkspaceLogger.general.info("Archiving thread: \(thread.id)")
            case .markAsRead:
                WorkspaceLogger.general.info("Marking thread as read: \(thread.id)")
            case .moveToFolder(let folder):
                WorkspaceLogger.general.info("Moving thread \(thread.id) to folder \(folder)")
            case .notify(let message):
                WorkspaceLogger.general.info("Rule Notification: \(message)")
            case .generateReply(let context):
                if let lastMessage = thread.messages.last {
                    _ = try? await mailAIService.generateReply(for: lastMessage, context: context)
                }
            case .createCalendarEvent:
                _ = try? await executionBridge.convertThreadToCalendarEvent(thread: thread)
            }
        }
    }

    private func loadRules() {
        guard let data = try? Data(contentsOf: rulesURL),
              let decoded = try? JSONDecoder().decode([AutomationRule].self, from: data) else { return }
        self.rules = decoded
    }

    func saveRules() {
        guard let data = try? JSONEncoder().encode(rules) else { return }
        try? data.write(to: rulesURL)
    }
}
