import Foundation
import Combine

/// Orchestrates the plugin lifecycle: creation, installation, activation, and Marketplace integration.
final class PluginManager: ObservableObject {
    static let shared = PluginManager()

    @Published private(set) var installedPlugins: [Plugin] = []
    @Published private(set) var marketplacePlugins: [Plugin] = []

    private let loader = PluginLoader()

    private init() {
        loadPlugins()
        seedMarketplace()
    }

    // MARK: - Lifecycle

    private func loadPlugins() {
        self.installedPlugins = loader.loadPlugins()
        for plugin in installedPlugins where plugin.isEnabled {
            registerCommands(plugin)
        }
    }

    private func savePlugins() {
        loader.savePlugins(installedPlugins)
    }

    func install(plugin: Plugin) {
        var p = plugin
        p.isInstalled = true
        p.isEnabled = true

        installedPlugins.append(p)
        registerCommands(p)
        savePlugins()
    }

    func uninstall(pluginID: UUID) {
        if let plugin = installedPlugins.first(where: { $0.id == pluginID }) {
            unregisterCommands(plugin)
        }
        installedPlugins.removeAll { $0.id == pluginID }
        savePlugins()
    }

    func togglePlugin(_ pluginID: UUID) {
        if let index = installedPlugins.firstIndex(where: { $0.id == pluginID }) {
            installedPlugins[index].isEnabled.toggle()
            let plugin = installedPlugins[index]
            if plugin.isEnabled {
                registerCommands(plugin)
            } else {
                unregisterCommands(plugin)
            }
            savePlugins()
        }
    }

    func updateLastExecuted(pluginID: UUID) {
        if let index = installedPlugins.firstIndex(where: { $0.id == pluginID }) {
            installedPlugins[index].lastExecutedAt = Date()
        }
    }

    // MARK: - Command Registration

    private func registerCommands(_ plugin: Plugin) {
        for command in plugin.commands {
            CommandEngine.shared.registerPluginCommand(command, pluginName: plugin.name)
        }
    }

    private func unregisterCommands(_ plugin: Plugin) {
        for command in plugin.commands {
            CommandEngine.shared.unregisterPluginCommand(commandID: command.id)
        }
    }

    // MARK: - Plugin Creation

    func createPlugin(
        name: String,
        identifier: String,
        description: String,
        icon: String,
        capabilities: Set<PluginCapability>,
        actions: Set<PluginAction>,
        permissions: Set<PluginPermission>,
        sourceCode: String
    ) -> Plugin {
        let newPlugin = Plugin(
            id: UUID(),
            identifier: identifier,
            name: name,
            description: description,
            icon: icon,
            version: "1.0.0",
            author: "Local User",
            capabilities: capabilities,
            actions: actions,
            commands: [],
            permissions: permissions,
            sourceCode: sourceCode,
            isEnabled: true,
            isInstalled: true,
            isUserCreated: true,
            createdAt: Date()
        )

        installedPlugins.append(newPlugin)
        savePlugins()
        return newPlugin
    }

    func updatePluginCode(pluginID: UUID, newSource: String) {
        if let index = installedPlugins.firstIndex(where: { $0.id == pluginID }) {
            installedPlugins[index].sourceCode = newSource
            savePlugins()
        }
    }

    // MARK: - Marketplace

    private func seedMarketplace() {
        marketplacePlugins = [
            Plugin(
                id: UUID(),
                identifier: "com.ToolsKit.GitHubPRWatcher",
                name: "GitHub PR Watcher",
                description: "Notifies you when a new PR is opened in your repositories.",
                icon: "arrow.triangle.pull",
                version: "1.2.0",
                author: "DevTools Inc",
                capabilities: [.github, .messaging],
                actions: [.repoPROpened],
                commands: [
                    PluginCommand(id: UUID(), keyword: "check prs", description: "Checks for open PRs", parameters: [])
                ],
                permissions: [.aiGenerate],
                sourceCode: "export function onEvent(event, ctx) { return 'PR Watcher Active'; }",
                isEnabled: false,
                isInstalled: false,
                isUserCreated: false,
                createdAt: Date()
            ),
            Plugin(
                id: UUID(),
                identifier: "com.ToolsKit.MeetingAssistant",
                name: "Meet Assistant",
                description: "Auto-starts a shared notebook when a meeting begins.",
                icon: "video.badge.plus",
                version: "2.1.0",
                author: "CollabCore",
                capabilities: [.meet, .notes],
                actions: [.meetStarted],
                commands: [],
                permissions: [.writeNotes],
                sourceCode: "export function onEvent(event, ctx) { ctx.notes.create('Meeting Notes'); return 'Created notebook'; }",
                isEnabled: false,
                isInstalled: false,
                isUserCreated: false,
                createdAt: Date()
            )
        ]
    }
}
