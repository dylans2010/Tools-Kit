import SwiftUI

struct ScopeInspectorView: View {
    @StateObject private var authorizationManager = AuthorizationManager.shared
    @StateObject private var moduleRegistry = SDKModuleRegistry.shared
    @StateObject private var pluginManager = SDKPluginManager.shared
    @StateObject private var connectorManager = SDKConnectorManager.shared

    var body: some View {
        List {
            Section("Active (Granted) Scopes") {
                if authorizationManager.currentScopes().isEmpty {
                    Text("No active scopes")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(authorizationManager.currentScopes(), id: \.self) { scope in
                        HStack {
                            Text(scope).font(.caption.monospaced())
                            Spacer()
                            Image(systemName: "checkmark.shield.fill").foregroundStyle(.green).font(.caption2)
                        }
                    }
                }
            }

            Section("Requested (Pending) Scopes") {
                let requested = getRequestedButUnusedScopes()
                if requested.isEmpty {
                    Text("No pending requests").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(requested, id: \.self) { scope in
                        HStack {
                            Text(scope).font(.caption.monospaced())
                            Spacer()
                            Image(systemName: "clock.fill").foregroundStyle(.orange).font(.caption2)
                        }
                    }
                }
            }

            Section("Unavailable (System) Scopes") {
                let unavailable = getUnavailableScopes()
                if unavailable.isEmpty {
                    Text("No unavailable scopes").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(unavailable, id: \.self) { scope in
                        HStack {
                            Text(scope).font(.caption.monospaced())
                            Spacer()
                            Image(systemName: "lock.slash.fill").foregroundStyle(.red).font(.caption2)
                        }
                    }
                }
            }

            Section("Usage Mapping") {
                ForEach(authorizationManager.currentScopes(), id: \.self) { scope in
                    DisclosureGroup(scope) {
                        resourceRows(for: scope)
                    }
                    .font(.caption.monospaced())
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Scope Inspector")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func resourceRows(for scope: String) -> some View {
        let modules = moduleRegistry.modules.filter { $0.requiredScopes.contains(scope) }
        let plugins = pluginManager.plugins.filter { $0.requiredScopes.contains(scope) }
        let connectors = connectorManager.connectors.filter { $0.requiredScopes.contains(scope) }

        if modules.isEmpty && plugins.isEmpty && connectors.isEmpty {
            Text("No resources depend on this scope")
                .foregroundStyle(.secondary)
        } else {
            ForEach(modules, id: \.id) { module in
                scopeRow("Module", name: module.displayName, allowed: authorizationManager.canAccessModule(id: module.identifier))
            }
            ForEach(plugins, id: \.id) { plugin in
                scopeRow("Plugin", name: plugin.name, allowed: authorizationManager.canUsePlugin(id: plugin.id))
            }
            ForEach(connectors, id: \.id) { connector in
                scopeRow("Connector", name: connector.name, allowed: authorizationManager.canUseConnector(id: connector.id))
            }
        }
    }

    private func scopeRow(_ type: String, name: String, allowed: Bool) -> some View {
        HStack {
            Text("\(type): \(name)")
            Spacer()
            Label(allowed ? "Allowed" : "Blocked", systemImage: allowed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .labelStyle(.iconOnly)
                .foregroundStyle(allowed ? Color.green : Color.red)
        }
    }

    private func getRequestedButUnusedScopes() -> [String] {
        let current = Set(authorizationManager.currentScopes())
        var requested = Set<String>()

        for plugin in pluginManager.plugins {
            requested.formUnion(plugin.requiredScopes)
        }
        for connector in connectorManager.connectors {
            requested.formUnion(connector.requiredScopes)
        }

        return requested.subtracting(current).sorted()
    }

    private func getUnavailableScopes() -> [String] {
        let allPossible = Set(PluginCapability.allCases.map { $0.rawValue })
        let current = Set(authorizationManager.currentScopes())
        return allPossible.subtracting(current).sorted()
    }
}
