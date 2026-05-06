import Foundation

public enum AutomationTrigger: Codable {
    case dataUpdated(scope: SDKScope)
    case connectorEvent(connectorID: UUID, eventName: String)
    case timeBased(interval: TimeInterval)
}

public enum AutomationCondition: Codable {
    case fieldEquals(key: String, value: String)
    case countExceeds(count: Int)
}

public enum AutomationAction: Codable {
    case runTool(toolID: UUID, input: [String: String])
    case syncConnector(connectorID: UUID)
    case sendNotification(title: String, body: String)
    case exportData(scope: SDKScope)
}

public struct SDKAutomationRule: Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var trigger: AutomationTrigger
    public var condition: AutomationCondition?
    public var action: AutomationAction
    public var isEnabled: Bool
    public var lastRunAt: Date?
    public var runCount: Int

    public init(id: UUID = UUID(), name: String, trigger: AutomationTrigger, condition: AutomationCondition? = nil, action: AutomationAction, isEnabled: Bool = true, lastRunAt: Date? = nil, runCount: Int = 0) {
        self.id = id
        self.name = name
        self.trigger = trigger
        self.condition = condition
        self.action = action
        self.isEnabled = isEnabled
        self.lastRunAt = lastRunAt
        self.runCount = runCount
    }
}

@MainActor
public final class SDKAutomationEngine: ObservableObject {
    public static let shared = SDKAutomationEngine()

    @Published public var rules: [SDKAutomationRule] = []

    private init() {}

    public func evaluate(trigger: AutomationTrigger, context: [String: Any]) async {
        let matchingRules = rules.filter { $0.isEnabled && matches(rule: $0, trigger: trigger) }
        for rule in matchingRules {
            if evaluateCondition(rule.condition, context: context) {
                do {
                    try await run(rule: rule, context: context)
                } catch {
                    Task { @MainActor in
                        SDKLogStore.shared.log("Automation failed: \(error.localizedDescription)", source: "SDKAutomationEngine", level: .error)
                    }
                }
            }
        }
    }

    public func run(rule: SDKAutomationRule, context: [String: Any]) async throws {
        SDKLogStore.shared.log("Running automation: \(rule.name)", source: "SDKAutomationEngine", level: .info)

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
            let data = try await ToolsKitSDK.shared.fetchData(scope: scope)
            let config = SDKExportConfig(
                projectName: "Automation Export",
                scopes: [scope],
                pluginIDs: [],
                toolIDs: [],
                connectorIDs: [],
                automationRules: [],
                exportedAt: Date()
            )
            _ = try await SDKExportService.shared.export(config: config)
        }

        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index].lastRunAt = Date()
            rules[index].runCount += 1
        }
    }

    public func add(_ rule: SDKAutomationRule) {
        rules.append(rule)
    }

    public func remove(id: UUID) {
        rules.removeAll { $0.id == id }
    }

    private func matches(rule: SDKAutomationRule, trigger: AutomationTrigger) -> Bool {
        // Implement matching logic based on trigger types
        return true
    }

    private func evaluateCondition(_ condition: AutomationCondition?, context: [String: Any]) -> Bool {
        guard let _ = condition else { return true }
        // Implement condition evaluation logic
        return true
    }
}
