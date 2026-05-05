import Foundation
import Combine

/// Manages the plugin lifecycle: install, enable/disable, sandbox execution.
final class PluginManager: ObservableObject {
    static let shared = PluginManager()

    @Published private(set) var installedPlugins: [PluginDefinition] = []
    @Published private(set) var availablePlugins: [PluginDefinition] = []

    private let storageKey = "installed_plugins_v2"

    private init() {
        loadInstalled()
        seedMarketplace()
    }

    // MARK: - Marketplace

    private func seedMarketplace() {
        availablePlugins = [
            PluginDefinition(
                id: UUID(),
                name: "Task Scheduler Pro",
                description: "Advanced scheduling with recurring tasks and calendar sync.",
                author: "ToolsKit Labs",
                version: "1.2.0",
                icon: "calendar.badge.clock",
                identifier: "com.ToolsKit.taskscheduler",
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
                identifier: "com.ToolsKit.codereview",
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
                identifier: "com.ToolsKit.analytics",
                capabilities: [.collaboration, .intelligence],
                actions: [.repoCommitPushed],
                sourceCode: "// JS Source code here"
            )
        ]
    }

    // MARK: - Management

    func install(pluginID: UUID) {
        guard let index = availablePlugins.firstIndex(where: { $0.id == pluginID }) else { return }
        var plugin = availablePlugins[index]
        plugin.isInstalled = true
        plugin.isEnabled = true
        plugin.installedAt = Date()

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
        if let index = installedPlugins.firstIndex(where: { $0.id == plugin.id }) {
            installedPlugins[index] = plugin
        } else {
            installedPlugins.append(plugin)
        }
        saveInstalled()
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
