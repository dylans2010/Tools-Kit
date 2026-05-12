import Foundation
import JavaScriptCore

/// Sandboxed execution environment for plugins.
/// Implements ScopeValidator, PluginPrerequisiteEngine, and PluginSecurityService logic.
final class PluginSandbox {
    nonisolated(unsafe) static let shared = PluginSandbox()

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

        // 3. Scope Validation
        if !validateScope(plugin: plugin, capability: event.capability) {
            return .failure(reason: .scopeInvalid, detail: "Security scope validation failed for \(event.capability.rawValue)")
        }

        // 4. Execution Rules Validation (NEW)
        for rule in plugin.executionRules {
            if !evaluateRule(rule, plugin: plugin, event: event) {
                return .failure(reason: .ruleBlocked, detail: "Execution blocked by rule: \(rule.type.rawValue)")
            }
        }

        // 5. Prerequisite Check
        let unmet = checkPrerequisites(plugin: plugin)
        if !unmet.isEmpty {
            return .failure(reason: .prerequisitesUnmet, detail: "Unmet prerequisites: \(unmet.map { $0.rawValue }.joined(separator: ", "))")
        }

        return .success
    }

    private func evaluateRule(_ rule: ExecutionRule, plugin: PluginDefinition, event: PluginEvent) -> Bool {
        // Simple evaluation logic for simulation
        switch rule.type {
        case .eventFilter:
            return true // Simplified
        case .frequencyLimit:
            if let limit = rule.limit, plugin.errorCount > limit { return false }
            return true
        default:
            return true
        }
    }

    private func validateScope(plugin: PluginDefinition, capability: PluginCapability) -> Bool {
        if capability.riskLevel == .high && (plugin.apiKey == nil || plugin.apiKey?.isEmpty == true) {
            return false
        }

        // External API scope check
        if capability == .externalApiSendRequest && plugin.endpoints.isEmpty {
            return false
        }

        return true
    }

    private func checkPrerequisites(plugin: PluginDefinition) -> [PluginPrerequisite] {
        var unmet: [PluginPrerequisite] = []

        for cap in plugin.capabilities {
            switch cap {
            case .notes: if !checkServiceEnabled(.notes) { unmet.append(.notes) }
            case .github: if !checkServiceEnabled(.repo) { unmet.append(.repo) }
            case .mail: if !checkServiceEnabled(.mail) { unmet.append(.mail) }
            case .ai, .aiPersonaQuery: if !checkServiceEnabled(.ai) { unmet.append(.ai) }
            case .automation: if !checkServiceEnabled(.automation) { unmet.append(.automation) }
            case .calendar: if !checkServiceEnabled(.calendar) { unmet.append(.calendar) }
            default: break
            }
        }

        return unmet
    }

    private func checkServiceEnabled(_ prerequisite: PluginPrerequisite) -> Bool {
        return true
    }

    // MARK: - Execution

    func execute(plugin: PluginDefinition, event: PluginEvent, useSDK: Bool = false) {
        // Core Execution Pipeline (Final)
        // 1. Capability Match
        // 2. Action Match
        // 3. Scope Validation
        // 4. Prerequisite Verification

        var result = validateExecution(plugin: plugin, event: event)

        if useSDK && plugin.capabilities.contains(.sdkDeveloperNoSandbox) {
            print("[SDK Sandbox] Bypassing restrictions for \(plugin.name)")
            result = .success
        }

        switch result {
        case .success:
            // 5. Inject Context & Toolkit
            performExecution(plugin: plugin, event: event, unrestricted: useSDK)
        case .failure(let reason, let detail):
            // 6. Block & Persist Logs
            print("Blocking plugin \(plugin.name) execution: \(reason.rawValue) - \(detail)")
            NotificationCenter.default.post(name: .pluginExecutionBlocked, object: nil, userInfo: ["pluginID": plugin.id, "reason": reason, "detail": detail])

            // Log rejection
            let log = ConnectorLog(connectorID: plugin.id, timestamp: Date(), type: .error, message: "Pipeline Blocked: \(reason.rawValue)", details: detail)
            ConnectorManager.shared.addLog(log)
        }
    }

    private func performExecution(plugin: PluginDefinition, event: PluginEvent, unrestricted: Bool = false) {
        guard let context = context else { return }

        if unrestricted {
            // Inject Master Workspace API in unrestricted mode
            let masterAPI: @convention(block) () -> [String: Any] = {
                return ["mode": "unrestricted", "access": "full"]
            }
            context.setObject(masterAPI, forKeyedSubscript: "sdk_master" as NSString)
        }

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

enum ValidationResult: Sendable {
    case success
    case failure(reason: ValidationFailureReason, detail: String)
}

enum ValidationFailureReason: String, Sendable {
    case capabilityMismatch = "Capability Mismatch"
    case actionMismatch = "Action Mismatch"
    case scopeInvalid = "Scope Invalid"
    case prerequisitesUnmet = "Prerequisites Unmet"
    case ruleBlocked = "Execution Rule Blocked"
}

extension NSNotification.Name {
    static let pluginExecutionBlocked = NSNotification.Name("com.toolskit.plugin.execution.blocked")
}
