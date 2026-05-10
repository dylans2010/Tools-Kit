// ToolsKit — SDKPluginRegistry.swift
// SDK Expansion — Phase 4

import Foundation
import Combine

/// Protocol for the plugin registry.
@MainActor
public protocol SDKPluginRegistryProtocol: AnyObject {
    func register(_ plugin: any SDKPluginConformable) throws
    func unregister(identifier: String) async throws
    func activate(identifier: String) async throws
    func deactivate(identifier: String) async throws
    func plugin(for identifier: String) -> (any SDKPluginConformable)?
    var registeredPlugins: [SDKPluginInfo] { get }
}

/// Centralized registry for all SDK plugins with lifecycle management.
@MainActor
public final class SDKPluginRegistry: SDKPluginRegistryProtocol, ObservableObject {
    public static let shared = SDKPluginRegistry()

    @Published public private(set) var registeredPlugins: [SDKPluginInfo] = []
    @Published public private(set) var activePluginCount: Int = 0

    private var plugins: [String: any SDKPluginConformable] = [:]
    private var phases: [String: SDKPluginPhase] = [:]
    public weak var lifecycleDelegate: SDKPluginLifecycleDelegate?

    private init() {}

    public func register(_ plugin: any SDKPluginConformable) throws {
        let identifier = plugin.pluginIdentifier
        guard plugins[identifier] == nil else {
            throw SDKPluginError.alreadyRegistered(identifier: identifier)
        }

        plugins[identifier] = plugin
        phases[identifier] = .unloaded

        let info = buildInfo(for: plugin, phase: .unloaded)
        registeredPlugins.append(info)

        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.plugins",
            name: "plugin.registered",
            data: ["identifier": identifier, "name": plugin.pluginDisplayName]
        ))

        SDKMetricsCollector.shared.increment("sdk.plugins.registered")
    }

    public func unregister(identifier: String) async throws {
        guard plugins[identifier] != nil else {
            throw SDKPluginError.notFound(identifier: identifier)
        }

        if phases[identifier] == .active {
            try await deactivate(identifier: identifier)
        }

        plugins.removeValue(forKey: identifier)
        phases.removeValue(forKey: identifier)
        registeredPlugins.removeAll { $0.identifier == identifier }
        updateActiveCount()

        SDKEventBus.shared.publish(SDKBusEvent(
            channel: "sdk.plugins",
            name: "plugin.unregistered",
            data: ["identifier": identifier]
        ))
    }

    public func activate(identifier: String) async throws {
        guard let plugin = plugins[identifier] else {
            throw SDKPluginError.notFound(identifier: identifier)
        }

        let currentPhase = phases[identifier] ?? .unloaded
        guard currentPhase == .unloaded || currentPhase == .paused || currentPhase == .disabled else {
            throw SDKPluginError.lifecycleViolation(phase: currentPhase.rawValue, attempted: SDKPluginPhase.active.rawValue)
        }

        lifecycleDelegate?.pluginWillActivate(identifier)
        phases[identifier] = .loading

        do {
            try await plugin.onActivate()
            phases[identifier] = .active
            updatePluginInfo(identifier: identifier, phase: .active)
            updateActiveCount()
            lifecycleDelegate?.pluginDidActivate(identifier)

            SDKEventBus.shared.publish(SDKBusEvent(
                channel: "sdk.plugins",
                name: "plugin.activated",
                data: ["identifier": identifier]
            ))

            SDKMetricsCollector.shared.increment("sdk.plugins.activations")
        } catch {
            phases[identifier] = .errored
            updatePluginInfo(identifier: identifier, phase: .errored)
            lifecycleDelegate?.pluginDidError(identifier, error: error)
            throw SDKPluginError.activationFailed(identifier: identifier, reason: error.localizedDescription)
        }
    }

    public func deactivate(identifier: String) async throws {
        guard let plugin = plugins[identifier] else {
            throw SDKPluginError.notFound(identifier: identifier)
        }

        guard phases[identifier] == .active || phases[identifier] == .paused else {
            throw SDKPluginError.lifecycleViolation(
                phase: (phases[identifier] ?? .unloaded).rawValue,
                attempted: "deactivate"
            )
        }

        lifecycleDelegate?.pluginWillDeactivate(identifier)

        do {
            try await plugin.onDeactivate()
            phases[identifier] = .disabled
            updatePluginInfo(identifier: identifier, phase: .disabled)
            updateActiveCount()
            lifecycleDelegate?.pluginDidDeactivate(identifier)

            SDKEventBus.shared.publish(SDKBusEvent(
                channel: "sdk.plugins",
                name: "plugin.deactivated",
                data: ["identifier": identifier]
            ))
        } catch {
            phases[identifier] = .errored
            updatePluginInfo(identifier: identifier, phase: .errored)
            lifecycleDelegate?.pluginDidError(identifier, error: error)
            throw error
        }
    }

    public func pause(identifier: String) async throws {
        guard let plugin = plugins[identifier] else {
            throw SDKPluginError.notFound(identifier: identifier)
        }
        guard phases[identifier] == .active else {
            throw SDKPluginError.lifecycleViolation(
                phase: (phases[identifier] ?? .unloaded).rawValue,
                attempted: SDKPluginPhase.paused.rawValue
            )
        }

        try await plugin.onPause()
        phases[identifier] = .paused
        updatePluginInfo(identifier: identifier, phase: .paused)
        updateActiveCount()
    }

    public func resume(identifier: String) async throws {
        guard let plugin = plugins[identifier] else {
            throw SDKPluginError.notFound(identifier: identifier)
        }
        guard phases[identifier] == .paused else {
            throw SDKPluginError.lifecycleViolation(
                phase: (phases[identifier] ?? .unloaded).rawValue,
                attempted: "resume"
            )
        }

        try await plugin.onResume()
        phases[identifier] = .active
        updatePluginInfo(identifier: identifier, phase: .active)
        updateActiveCount()
    }

    public func plugin(for identifier: String) -> (any SDKPluginConformable)? {
        plugins[identifier]
    }

    public func phase(for identifier: String) -> SDKPluginPhase {
        phases[identifier] ?? .unloaded
    }

    public func plugins(inCategory category: SDKPluginCategory) -> [SDKPluginInfo] {
        registeredPlugins.filter { $0.category == category }
    }

    public func healthCheck(identifier: String) async -> SDKHealthStatus {
        guard let plugin = plugins[identifier] else { return .unknown }
        return await plugin.healthCheck()
    }

    private func buildInfo(for plugin: any SDKPluginConformable, phase: SDKPluginPhase) -> SDKPluginInfo {
        SDKPluginInfo(
            id: plugin.id,
            identifier: plugin.pluginIdentifier,
            displayName: plugin.pluginDisplayName,
            version: plugin.pluginVersion,
            description: plugin.pluginDescription,
            category: plugin.pluginCategory,
            capabilities: plugin.requiredCapabilities,
            scopes: plugin.requiredScopes,
            phase: phase
        )
    }

    private func updatePluginInfo(identifier: String, phase: SDKPluginPhase) {
        guard let index = registeredPlugins.firstIndex(where: { $0.identifier == identifier }),
              let plugin = plugins[identifier] else { return }
        registeredPlugins[index] = buildInfo(for: plugin, phase: phase)
    }

    private func updateActiveCount() {
        activePluginCount = phases.values.filter { $0 == .active }.count
    }
}
