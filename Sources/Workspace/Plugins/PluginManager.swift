import Foundation
import Combine

// MARK: - Plugin Model

/// A self-contained feature module for ToolsKit.
struct PluginDefinition: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    var version: String
    var author: String
    var category: PluginCategory
    var icon: String
    var isEnabled: Bool
    var isInstalled: Bool
    var commands: [PluginCommand]
    var targetSystems: [PluginTarget]
    var installedAt: Date?

    enum PluginCategory: String, Codable, CaseIterable {
        case collaborationTool = "Collaboration Tool"
        case githubTool = "GitHub Tool"
        case workflowExtension = "Workflow Extension"
        case automationTrigger = "Automation Trigger"
        case analytics = "Analytics"
        case utility = "Utility"
    }

    enum PluginTarget: String, Codable, CaseIterable {
        case collaboration = "Collaboration"
        case github = "GitHub"
        case global = "Global"
    }
}

struct PluginCommand: Codable, Identifiable {
    let id: UUID
    var keyword: String
    var description: String
    var parameters: [String]
}

// MARK: - Plugin Manager

/// Manages the plugin lifecycle: install, enable/disable, sandbox execution.
final class PluginManager: ObservableObject {
    static let shared = PluginManager()

    @Published private(set) var installedPlugins: [PluginDefinition] = []
    @Published private(set) var availablePlugins: [PluginDefinition] = []

    private let storageFile = "installed_plugins.json"

    private init() {
        loadInstalled()
        seedMarketplace()
    }

    // MARK: - Marketplace

    private func seedMarketplace() {
        availablePlugins = [
            PluginDefinition(
                id: UUID(), name: "Task Scheduler Pro",
                description: "Advanced scheduling with recurring tasks and calendar sync.",
                version: "1.2.0", author: "ToolsKit Labs", category: .collaborationTool,
                icon: "calendar.badge.clock", isEnabled: false, isInstalled: false,
                commands: [PluginCommand(id: UUID(), keyword: "schedule task", description: "Schedule a recurring task", parameters: ["title", "interval"])],
                targetSystems: [.collaboration], installedAt: nil
            ),
            PluginDefinition(
                id: UUID(), name: "Code Review Assistant",
                description: "AI-powered inline code review and suggestion engine.",
                version: "2.0.1", author: "DevOps Team", category: .githubTool,
                icon: "eye.fill", isEnabled: false, isInstalled: false,
                commands: [PluginCommand(id: UUID(), keyword: "review pr", description: "Review a pull request", parameters: ["pr_number"])],
                targetSystems: [.github], installedAt: nil
            ),
            PluginDefinition(
                id: UUID(), name: "Workspace Analytics Dashboard",
                description: "Deep contributor scoring, timeline heatmaps, and activity reports.",
                version: "1.0.5", author: "Analytics Core", category: .analytics,
                icon: "chart.bar.xaxis", isEnabled: false, isInstalled: false,
                commands: [PluginCommand(id: UUID(), keyword: "analytics report", description: "Generate an analytics report", parameters: ["spaceID"])],
                targetSystems: [.collaboration], installedAt: nil
            ),
            PluginDefinition(
                id: UUID(), name: "Auto Release Notes",
                description: "Generates semantic release notes from commit history.",
                version: "1.3.2", author: "Release Tools", category: .githubTool,
                icon: "doc.badge.plus", isEnabled: false, isInstalled: false,
                commands: [PluginCommand(id: UUID(), keyword: "generate release notes", description: "Auto-generate release notes", parameters: ["tag"])],
                targetSystems: [.github], installedAt: nil
            ),
            PluginDefinition(
                id: UUID(), name: "Inactivity Alert",
                description: "Detects and notifies workspace inactivity periods.",
                version: "1.0.0", author: "Automation Core", category: .automationTrigger,
                icon: "bell.badge.slash", isEnabled: false, isInstalled: false,
                commands: [PluginCommand(id: UUID(), keyword: "check inactivity", description: "Check workspace inactivity", parameters: ["days"])],
                targetSystems: [.collaboration, .global], installedAt: nil
            ),
            PluginDefinition(
                id: UUID(), name: "Branch Cleanup",
                description: "Identifies and removes stale branches automatically.",
                version: "1.1.0", author: "GitOps Team", category: .workflowExtension,
                icon: "arrow.triangle.branch", isEnabled: false, isInstalled: false,
                commands: [PluginCommand(id: UUID(), keyword: "clean branches", description: "Clean stale branches", parameters: [])],
                targetSystems: [.github], installedAt: nil
            ),
        ]
    }

    // MARK: - Install / Uninstall

    func install(pluginID: UUID) {
        guard let index = availablePlugins.firstIndex(where: { $0.id == pluginID }) else { return }
        guard validate(plugin: availablePlugins[index]) else { return }
        var plugin = availablePlugins[index]
        plugin.isInstalled = true
        plugin.isEnabled = true
        plugin.installedAt = Date()
        availablePlugins[index] = plugin
        installedPlugins.removeAll { $0.id == pluginID }
        installedPlugins.append(plugin)
        registerCommands(plugin)
        saveInstalled()
    }

    func uninstall(pluginID: UUID) {
        if let plugin = installedPlugins.first(where: { $0.id == pluginID }) {
            unregisterCommands(plugin: plugin)
        }
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
        if let j = availablePlugins.firstIndex(where: { $0.id == pluginID }) {
            availablePlugins[j].isEnabled = installedPlugins[i].isEnabled
        }
        saveInstalled()
    }

    /// Validates a plugin definition before installation.
    /// Version must follow strict major.minor.patch semver format (e.g. "1.2.0"). Pre-release
    /// suffixes (e.g. "1.0.0-beta") and "v" prefixes are not supported.
    func validate(plugin: PluginDefinition) -> Bool {
        guard !plugin.name.isEmpty, !plugin.version.isEmpty else { return false }
        let parts = plugin.version.split(separator: ".")
        guard parts.count == 3, parts.allSatisfy({ Int($0) != nil }) else { return false }
        return true
    }

    // MARK: - Command Registration

    private func registerCommands(_ plugin: PluginDefinition) {
        for command in plugin.commands {
            CommandEngine.shared.registerPluginCommand(command, pluginName: plugin.name)
        }
    }

    private func unregisterCommands(plugin: PluginDefinition) {
        for command in plugin.commands {
            CommandEngine.shared.unregisterPluginCommand(commandID: command.id)
        }
    }

    // MARK: - Execution

    func execute(pluginID: UUID, command: String, parameters: [String: String] = [:]) -> String {
        guard let plugin = installedPlugins.first(where: { $0.id == pluginID }), plugin.isEnabled else {
            return "Plugin not available or disabled."
        }
        return "[\(plugin.name)] Executed '\(command)' with \(parameters.count) parameter(s). ✓"
    }

    // MARK: - Persistence

    private func saveInstalled() {
        let s = installedPlugins
        DispatchQueue.global(qos: .utility).async {
            try? WorkspacePersistence.shared.save(s, to: self.storageFile)
        }
    }

    private func loadInstalled() {
        if WorkspacePersistence.shared.exists(filename: storageFile) {
            installedPlugins = (try? WorkspacePersistence.shared.load([PluginDefinition].self, from: storageFile)) ?? []
        }
    }
}
