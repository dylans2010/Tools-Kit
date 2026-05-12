import Foundation
import Combine
import UserNotifications

public struct SDKAutomationRule: Identifiable, Codable, Sendable {
    public var id: UUID
    public var name: String
    public var trigger: AutomationTrigger
    public var condition: AutomationCondition?
    public var action: AutomationAction
    public var isEnabled: Bool
    public var lastRunAt: Date?
    public var runCount: Int
}

public enum AutomationTrigger: Codable, Sendable {
    case dataUpdated(scope: String)
    case connectorEvent(connectorID: UUID, eventName: String)
    case timeBased(interval: TimeInterval)
}

public enum AutomationCondition: Codable, Sendable {
    case fieldEquals(key: String, value: String)
    case countExceeds(count: Int)
}

public enum AutomationAction: Codable, Sendable {
    case runTool(toolID: UUID, input: [String: String])
    case syncConnector(connectorID: UUID)
    case sendNotification(title: String, body: String)
    case exportData(scope: String)
}

@MainActor
public final class SDKAutomationEngine: ObservableObject {
    nonisolated(unsafe) public static let shared = SDKAutomationEngine()

    @Published public var rules: [SDKAutomationRule] = []

    private init() {
        // Rules are loaded from SDKProjectManager
    }

    public func evaluate(trigger: AutomationTrigger, context: [String: Any]) async {
        let rulesToRun = rules.filter { rule in
            rule.isEnabled && matches(rule.trigger, trigger)
        }

        for rule in rulesToRun {
            if checkCondition(rule.condition, context: context) {
                do {
                    try await run(rule: rule, context: context)
                } catch {
                    SDKLogStore.shared.log("Automation rule '\(rule.name)' failed: \(error.localizedDescription)", source: "SDKAutomationEngine", level: LogLevel.error)
                }
            }
        }
    }

    public func run(rule: SDKAutomationRule, context: [String: Any]) async throws {
        SDKLogStore.shared.log("Running automation: \(rule.name)", source: "SDKAutomationEngine", level: LogLevel.info)

        switch rule.action {
        case .runTool(let toolID, let input):
            _ = try await SDKToolManager.shared.execute(toolID: toolID, input: input)
        case .syncConnector(let connectorID):
            if let connector = SDKConnectorManager.shared.connectors.first(where: { $0.id == connectorID }) {
                try await connector.sync()
            }
        case .sendNotification(let title, let body):
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            try await UNUserNotificationCenter.current().add(request)
        case .exportData(let scope):
            let config = SDKExportConfig(
                projectName: "auto_export_\(scope)",
                scopes: SDKScope.allCases.filter { String(describing: $0) == scope },
                pluginIDs: [],
                toolIDs: [],
                connectorIDs: [],
                automationRules: [],
                exportedAt: Date()
            )
            _ = try await SDKExportService().export(config: config)
            SDKLogStore.shared.log("Auto-export completed for \(scope)", source: "SDKAutomationEngine", level: LogLevel.info)
        }

        // Update rule stats in ProjectManager
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index].lastRunAt = Date()
            rules[index].runCount += 1
            SDKProjectManager.shared.currentProject?.automationRules = rules
            try? SDKProjectManager.shared.save()
        }
    }

    public func add(_ rule: SDKAutomationRule) {
        rules.append(rule)
        SDKProjectManager.shared.currentProject?.automationRules = rules
        try? SDKProjectManager.shared.save()
    }

    public func remove(id: UUID) {
        rules.removeAll { $0.id == id }
        SDKProjectManager.shared.currentProject?.automationRules = rules
        try? SDKProjectManager.shared.save()
    }

    private func matches(_ trigger1: AutomationTrigger, _ trigger2: AutomationTrigger) -> Bool {
        // Simple matching logic
        switch (trigger1, trigger2) {
        case (.dataUpdated(let s1), .dataUpdated(let s2)): return s1 == s2
        case (.connectorEvent(let id1, let e1), .connectorEvent(let id2, let e2)): return id1 == id2 && e1 == e2
        default: return false
        }
    }

    private func checkCondition(_ condition: AutomationCondition?, context: [String: Any]) -> Bool {
        guard let condition = condition else { return true }
        switch condition {
        case .fieldEquals(let key, let value):
            return (context[key] as? String) == value
        case .countExceeds(let count):
            return (context["count"] as? Int ?? 0) > count
        }
    }
}
