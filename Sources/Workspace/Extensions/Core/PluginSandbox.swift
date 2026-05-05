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
        // Implementation of Notes, Mail, Tasks, AI, etc. APIs for JS environment
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

        // 3. Scope Validation (PluginSecurityService / ScopeValidator)
        if !validateScope(plugin: plugin, capability: event.capability) {
            return .failure(reason: .scopeInvalid, detail: "Security scope validation failed for \(event.capability.rawValue)")
        }

        // 4. Prerequisite Check (PluginPrerequisiteEngine)
        let unmet = checkPrerequisites(plugin: plugin)
        if !unmet.isEmpty {
            return .failure(reason: .prerequisitesUnmet, detail: "Unmet prerequisites: \(unmet.map { $0.rawValue }.joined(separator: ", "))")
        }

        return .success
    }

    private func validateScope(plugin: PluginDefinition, capability: PluginCapability) -> Bool {
        // High-risk scopes must have API key and privacy note (enforced at install/save)
        // Here we can do runtime checks, e.g. checking if system-wide toggles are on.
        if capability.riskLevel == .high && (plugin.apiKey == nil || plugin.apiKey?.isEmpty == true) {
            return false
        }
        return true
    }

    private func checkPrerequisites(plugin: PluginDefinition) -> [PluginPrerequisite] {
        var unmet: [PluginPrerequisite] = []

        // Map capabilities to prerequisites for this check
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
        // In a real system, this would check actual service availability
        // For simulation, we assume services are available unless specified otherwise
        return true
    }

    // MARK: - Execution

    func execute(plugin: PluginDefinition, event: PluginEvent) {
        let result = validateExecution(plugin: plugin, event: event)

        switch result {
        case .success:
            performExecution(plugin: plugin, event: event)
        case .failure(let reason, let detail):
            print("Blocking plugin \(plugin.name) execution: \(reason.rawValue) - \(detail)")
            // Routing to PluginLimitedView is handled by the UI/Runtime layer via a notification or state change
            NotificationCenter.default.post(name: .pluginExecutionBlocked, object: nil, userInfo: ["pluginID": plugin.id, "reason": reason, "detail": detail])
        }
    }

    private func performExecution(plugin: PluginDefinition, event: PluginEvent) {
        guard let context = context else { return }

        // Inject event payload
        context.setObject(event.payload, forKeyedSubscript: "eventPayload" as NSString)

        // Execute source
        context.evaluateScript(plugin.sourceCode)

        // Log to DevConsole (simulated)
        print("Executed plugin \(plugin.name) successfully.")
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
}

extension NSNotification.Name {
    static let pluginExecutionBlocked = NSNotification.Name("com.toolskit.plugin.execution.blocked")
}
