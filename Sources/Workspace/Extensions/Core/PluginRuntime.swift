import Foundation
import Combine

/// Manages the live execution environment for plugins.
final class PluginRuntime: ObservableObject {
    static let shared = PluginRuntime()

    private var sandboxes: [UUID: PluginSandbox] = [:]
    private var cancellables = Set<AnyCancellable>()
    private let loader = PluginLoader()

    @Published private(set) var logs: [PluginExecutionLog] = []

    private init() {
        self.logs = loader.loadLogs()
        setupEventSubscription()
    }

    private func setupEventSubscription() {
        PluginEventBus.shared.events
            .sink { [weak self] event in
                self?.handleEvent(event)
            }
            .store(in: &cancellables)
    }

    private func handleEvent(_ event: PluginEvent) {
        let plugins = PluginManager.shared.installedPlugins.filter { $0.isEnabled }

        for plugin in plugins {
            // Rule: Plugin executes ONLY if event.capability ∈ plugin.capabilities AND event.action ∈ plugin.actions
            if plugin.capabilities.contains(event.capability) && plugin.actions.contains(event.type) {
                executePlugin(plugin, with: event)
            }
        }
    }

    private func executePlugin(_ plugin: Plugin, with event: PluginEvent) {
        let sandbox = sandboxes[plugin.id] ?? PluginSandbox(plugin: plugin)
        sandboxes[plugin.id] = sandbox

        let output = sandbox.execute(event: event)

        let log = PluginExecutionLog(
            id: UUID(),
            pluginID: plugin.id,
            eventID: event.id,
            timestamp: Date(),
            output: output,
            status: output.starts(with: "Error") ? .failure : .success
        )

        DispatchQueue.main.async {
            self.logs.insert(log, at: 0)
            if self.logs.count > 100 {
                self.logs.removeLast()
            }
            self.loader.saveLogs(self.logs)

            // Update last executed date on plugin
            PluginManager.shared.updateLastExecuted(pluginID: plugin.id)
        }

        print("[PluginRuntime] Executed '\(plugin.name)' for '\(event.type.rawValue)': \(output)")
    }
}
