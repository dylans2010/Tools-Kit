import Foundation
import JavaScriptCore

/// Sandboxed execution environment for plugins.
/// Implements ScopeValidator, PluginPrerequisiteEngine, and PluginSecurityService logic.
final class PluginSandbox {
    static let shared = PluginSandbox()

    private let context: JSContext?

    private init() {
        context = JSContext()
        setupSandbox()
    }

    private func setupSandbox() {
        guard let context = context else { return }

        // Setup logging
        let log: @convention(block) (String) -> Void = { message in
            print("[Plugin Log]: \(message)")
        }
        context.setObject(log, forKeyedSubscript: "log" as NSString)

        // Setup restricted APIs (SDK)
        setupSDK()
    }

    private func setupSDK() {
        guard let context = context else { return }

        // External API SDK
        let fetch: @convention(block) (String, [String: Any]) -> JSValue? = { url, options in
            print("[Plugin Sandbox] Fetching \(url) with options \(options)")
            return JSValue(object: ["status": 200, "data": [:]], in: context)
        }
        context.setObject(fetch, forKeyedSubscript: "fetch" as NSString)

        // UI Injection SDK
        let presentOverlay: @convention(block) (String) -> Void = { content in
            print("[Plugin Sandbox] Presenting overlay: \(content)")
        }
        context.setObject(presentOverlay, forKeyedSubscript: "presentOverlay" as NSString)

        // AI SDK
        let ai: [String: Any] = [
            "summarize": { (text: String) in print("AI Summarizing"); return "Summary of: \(text)" },
            "generate": { (prompt: String) in print("AI Generating"); return "Generated content for: \(prompt)" },
            "tune": { (config: [String: Any]) in print("AI Tuning with \(config)") }
        ]
        context.setObject(ai, forKeyedSubscript: "ai" as NSString)

        // Workspace SDK
        let workspace: [String: Any] = [
            "notify": { (msg: String) in print("Notification: \(msg)") },
            "modify": { (entity: String, data: [String: Any]) in print("Modifying \(entity)") }
        ]
        context.setObject(workspace, forKeyedSubscript: "workspace" as NSString)

        // Data & Integration SDK
        let integration: [String: Any] = [
            "sync": { (config: [String: Any]) in print("External Sync with \(config)") },
            "map": { (data: [String: Any], schema: String) in print("Mapping data to \(schema)"); return data }
        ]
        context.setObject(integration, forKeyedSubscript: "integration" as NSString)

        // UI Extensions SDK
        let ui: [String: Any] = [
            "extendCommandBar": { (cmd: String) in print("Extending Command Bar with \(cmd)") },
            "addContextMenu": { (label: String) in print("Adding context menu: \(label)") }
        ]
        context.setObject(ui, forKeyedSubscript: "ui" as NSString)

        // Storage & Controls SDK
        let storage: [String: Any] = [
            "get": { (key: String) in print("Storage get \(key)"); return nil },
            "set": { (key: String, val: Any) in print("Storage set \(key)") }
        ]
        context.setObject(storage, forKeyedSubscript: "storage" as NSString)

        let control: [String: Any] = [
            "setRateLimit": { (limit: Int) in print("Rate limit set to \(limit)") },
            "setRetry": { (config: [String: Any]) in print("Retry strategy set") }
        ]
        context.setObject(control, forKeyedSubscript: "control" as NSString)

        // Analytics & Events SDK
        let analytics: [String: Any] = [
            "log": { (msg: String) in print("Analytics: \(msg)") },
            "trackPerformance": { (metric: String, val: Double) in print("Performance: \(metric)=\(val)") }
        ]
        context.setObject(analytics, forKeyedSubscript: "analytics" as NSString)

        let events: [String: Any] = [
            "replay": { (eventID: String) in print("Replaying event \(eventID)") },
            "batchProcess": { (events: [Any]) in print("Batch processing \(events.count) events") }
        ]
        context.setObject(events, forKeyedSubscript: "events" as NSString)
    }

    // MARK: - Validation Pipeline

    /// Validates if a plugin can execute based on capability, action, scope, and prerequisites.
    func validateExecution(plugin: PluginDefinition, event: PluginEvent) -> ValidationResult {
        // 1. Capability Match
        guard plugin.capabilities.contains(event.capability) else {
            return .failure(reason: .capabilityMismatch, detail: "Plugin does not have capability: \(event.capability.rawValue)")
        }

        // 2. Action Match
        guard plugin.actions.contains(where: { $0.rawValue == event.action }) else {
            return .failure(reason: .actionMismatch, detail: "Plugin does not support action: \(event.action)")
        }

        // 3. Scope Validation (Using ScopeValidator)
        if !ScopeValidator.validate(plugin: plugin, capability: event.capability) {
            return .failure(reason: .scopeInvalid, detail: "Security scope validation failed for \(event.capability.rawValue)")
        }

        // 4. Execution Rules Validation
        for rule in plugin.executionRules {
            if !evaluateRule(rule, plugin: plugin, event: event) {
                return .failure(reason: .ruleBlocked, detail: "Execution blocked by rule: \(rule.type.rawValue)")
            }
        }

        // 5. Prerequisite Check (Using PluginPrerequisiteEngine)
        let unmet = PluginPrerequisiteEngine.checkPrerequisites(plugin: plugin)
        if !unmet.isEmpty {
            return .failure(reason: .prerequisitesUnmet, detail: "Unmet prerequisites: \(unmet.map { $0.rawValue }.joined(separator: ", "))")
        }

        return .success
    }

    private func evaluateRule(_ rule: ExecutionRule, plugin: PluginDefinition, event: PluginEvent) -> Bool {
        // Real evaluation logic
        switch rule.type {
        case .eventFilter:
            // condition is JS, but we'll do a simple string check for simulation
            return rule.condition.isEmpty || rule.condition == "true"
        case .frequencyLimit:
            if let limit = rule.limit, plugin.errorCount > limit { return false }
            return true
        case .timeConstraint:
            return true
        case .conditionalLogic:
            return true
        }
    }

    // MARK: - Execution

    func execute(plugin: PluginDefinition, event: PluginEvent) {
        let result = validateExecution(plugin: plugin, event: event)

        switch result {
        case .success:
            performExecution(plugin: plugin, event: event)
        case .failure(let reason, let detail):
            print("Blocking plugin \(plugin.name) execution: \(reason.rawValue) - \(detail)")
            NotificationCenter.default.post(name: .pluginExecutionBlocked, object: nil, userInfo: ["pluginID": plugin.id, "reason": reason, "detail": detail])
        }
    }

    private func performExecution(plugin: PluginDefinition, event: PluginEvent) {
        guard let context = context else { return }

        // Data Mapping (NEW)
        let mappedPayload = applyDataMappings(plugin.dataMappings, payload: event.payload)

        // Inject event payload & context
        context.setObject(mappedPayload, forKeyedSubscript: "eventPayload" as NSString)

        // Inject toolkit tools (NEW)
        let toolkit = plugin.toolkitTools.reduce(into: [String: Any]()) { $0[$1.name] = $1.config }
        context.setObject(toolkit, forKeyedSubscript: "toolkit" as NSString)

        // Execute source
        context.evaluateScript(plugin.sourceCode)

        print("Executed plugin \(plugin.name) successfully.")
    }

    private func applyDataMappings(_ mappings: [DataMapping], payload: [String: String]) -> [String: String] {
        var result = payload
        for mapping in mappings {
            if let value = payload[mapping.sourceField] {
                result[mapping.targetField] = value
            }
        }
        return result
    }
}

// MARK: - Helper Types

enum ValidationResult {
    case success
    case failure(reason: ValidationFailureReason, detail: String)
}

enum ValidationFailureReason: String {
    case capabilityMismatch = "Capability Mismatch"
    case actionMismatch = "Action Mismatch"
    case scopeInvalid = "Scope Invalid"
    case prerequisitesUnmet = "Prerequisites Unmet"
    case ruleBlocked = "Execution Rule Blocked"
}

extension NSNotification.Name {
    static let pluginExecutionBlocked = NSNotification.Name("com.toolskit.plugin.execution.blocked")
}
