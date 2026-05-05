import Foundation
import Combine

/// Manages the plugin lifecycle: install, enable/disable, sandbox execution.
/// Acts as the PluginRegistry and PluginLifecycleManager.
final class PluginManager: ObservableObject {
    static let shared = PluginManager()

    @Published private(set) var installedPlugins: [PluginDefinition] = []
    @Published private(set) var availablePlugins: [PluginDefinition] = []

    private let storageKey = "installed_plugins_v2"

    private init() {
        loadInstalled()
        seedMarketplace()
    }

    // MARK: - Marketplace (PluginRegistry)

    private func seedMarketplace() {
        availablePlugins = [
            PluginDefinition(
                id: UUID(),
                name: "Task Scheduler Pro",
                description: "Advanced scheduling with recurring tasks and calendar sync.",
                author: "ToolsKit Labs",
                version: "1.2.0",
                icon: "calendar.badge.clock",
                identifier: "com.toolskit.taskscheduler",
                capabilities: [.tasks, .calendar],
                actions: [.taskCreated, .calendarEventCreated],
                sourceCode: "// JS Source code here"
            ),
            PluginDefinition(
                id: UUID(),
                name: "Code Review Assistant",
                description: "AI-powered inline code review and suggestion engine.",
                author: "DevOps Team",
                version: "2.0.1",
                icon: "eye.fill",
                identifier: "com.toolskit.codereview",
                capabilities: [.github, .ai],
                actions: [.repoPROpened],
                sourceCode: "// JS Source code here"
            ),
            PluginDefinition(
                id: UUID(),
                name: "Workspace Analytics",
                description: "Deep contributor scoring, timeline heatmaps, and activity reports.",
                author: "Analytics Core",
                version: "1.0.5",
                icon: "chart.bar.xaxis",
                identifier: "com.toolskit.analytics",
                capabilities: [.collaboration, .intelligence],
                actions: [.repoCommitPushed],
                sourceCode: "// JS Source code here"
            ),
            PluginDefinition(
                id: UUID(),
                name: "Persona Insights",
                description: "AI Persona driven behavioral modeling and workspace analysis.",
                author: "Intelligence Team",
                version: "1.0.0",
                icon: "person.and.sparkles",
                identifier: "com.toolskit.personainsights",
                capabilities: [.aiPersonaQuery, .aiPersonaWorkspaceAnalysis, .aiPersonaBehaviorModel],
                actions: [.workspaceEvent],
                sourceCode: "// JS Source code here"
            )
        ]
    }

    // MARK: - Management (PluginLifecycleManager)

    func install(pluginID: UUID) {
        guard let index = availablePlugins.firstIndex(where: { $0.id == pluginID }) else { return }
        var plugin = availablePlugins[index]

        // Validation check before installation
        guard validatePluginForInstall(plugin) else { return }

        plugin.isInstalled = true
        plugin.isEnabled = true
        plugin.installedAt = Date()

        // Add initial changelog entry
        plugin.changelog.append(PluginChangeLogEntry(version: plugin.version, date: Date(), notes: "Initial installation"))

        availablePlugins[index] = plugin
        installedPlugins.append(plugin)
        saveInstalled()
    }

    func uninstall(pluginID: UUID) {
        installedPlugins.removeAll { $0.id == pluginID }
        if let i = availablePlugins.firstIndex(where: { $0.id == pluginID }) {
            availablePlugins[i].isInstalled = false
            availablePlugins[i].isEnabled = false
            availablePlugins[i].installedAt = nil
        }
        saveInstalled()
    }

    func toggle(pluginID: UUID) {
        guard let i = installedPlugins.firstIndex(where: { $0.id == pluginID }) else { return }
        installedPlugins[i].isEnabled.toggle()
        saveInstalled()
    }

    func savePlugin(_ plugin: PluginDefinition) {
        // Identifier Locking: Check if a plugin with same identifier exists but different ID
        if let existing = installedPlugins.first(where: { $0.identifier == plugin.identifier }), existing.id != plugin.id {
            print("Error: Plugin identifier \(plugin.identifier) is locked.")
            return
        }

        if let index = installedPlugins.firstIndex(where: { $0.id == plugin.id }) {
            var updatedPlugin = plugin
            let currentVersion = installedPlugins[index].version

            // Versioning: Must increment
            if isNewerVersion(new: plugin.version, current: currentVersion) {
                updatedPlugin.changelog.append(PluginChangeLogEntry(version: plugin.version, date: Date(), notes: plugin.releaseNotes ?? "Version updated"))
            } else if plugin.version != currentVersion {
                print("Warning: Version should be incremented. Current: \(currentVersion), New: \(plugin.version)")
                // Optionally block save if version is not incremented? Spec says "must increment"
                // For now we allow it but log a warning, or we could revert version.
                updatedPlugin.version = currentVersion
            }

            // Keep immutable fields
            updatedPlugin.identifier = installedPlugins[index].identifier

            installedPlugins[index] = updatedPlugin
        } else {
            var newPlugin = plugin
            newPlugin.changelog.append(PluginChangeLogEntry(version: plugin.version, date: Date(), notes: "Plugin created"))
            installedPlugins.append(newPlugin)
        }
        saveInstalled()
    }

    // MARK: - Validation

    private func validatePluginForInstall(_ plugin: PluginDefinition) -> Bool {
        // Enforce identifier format: com.toolskit.<name>
        if !plugin.identifier.starts(with: "com.toolskit.") {
            return false
        }

        // High-risk scopes require API key and privacy note
        let hasHighRisk = plugin.capabilities.contains { $0.riskLevel == .high }
        if hasHighRisk {
            if plugin.apiKey == nil || plugin.privacyNote == nil {
                return false
            }
        }

        return true
    }

    private func isNewerVersion(new: String, current: String) -> Bool {
        let newParts = new.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(newParts.count, currentParts.count) {
            let n = i < newParts.count ? newParts[i] : 0
            let c = i < currentParts.count ? currentParts[i] : 0
            if n > c { return true }
            if n < c { return false }
        }
        return false
    }

    // MARK: - Persistence

    private func saveInstalled() {
        let plugins = installedPlugins
        DispatchQueue.global(qos: .utility).async {
            try? UnifiedDataStore.shared.save(plugins, key: self.storageKey)
        }
    }

    private func loadInstalled() {
        if UnifiedDataStore.shared.exists(key: storageKey) {
            installedPlugins = (try? UnifiedDataStore.shared.load([PluginDefinition].self, key: storageKey)) ?? []
        }
    }
}
