import SwiftUI

struct ScopeInspectorView: View {
    @ObservedObject private var authorizationManager = AuthorizationManager.shared
    @ObservedObject private var moduleRegistry = SDKModuleRegistry.shared
    @ObservedObject private var pluginManager = SDKPluginManager.shared
    @ObservedObject private var connectorManager = SDKConnectorManager.shared

    @State private var query = ""
    @State private var showOnlyBlocked = false

    var body: some View {
        List {
            Section("Overview") {
                LabeledContent("Active Scope Count", value: "\(authorizationManager.currentScopes().count)")
                LabeledContent("Violations", value: "\(authorizationManager.securityViolations.count)")
                Toggle("Show only blocked resources", isOn: $showOnlyBlocked)
            }

            Section("Active Scopes") {
                let activeScopes = authorizationManager.currentScopes()
                    .filter { query.isEmpty || $0.localizedCaseInsensitiveContains(query) }
                if activeScopes.isEmpty {
                    Text("No active scopes")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(activeScopes, id: \.self) { scope in
                        Text(scope).font(.caption.monospaced())
                    }
                }
            }

            ForEach(authorizationManager.currentScopes().filter { query.isEmpty || $0.localizedCaseInsensitiveContains(query) }, id: \.self) { scope in
                Section(scope) {
                    resourceRows(for: scope)
                }
            }

            Section("Recent Violations") {
                if authorizationManager.securityViolations.isEmpty {
                    Text("No violations detected")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(authorizationManager.securityViolations) { violation in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(violation.scope)
                                    .font(.caption.monospaced().bold())
                                Spacer()
                                Text(violation.timestamp, style: .time)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Text("\(violation.resourceType): \(violation.resourceId)")
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Scope Inspector")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Filter scopes")
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
                let allowed = authorizationManager.canAccessModule(id: module.identifier)
                if !showOnlyBlocked || !allowed {
                    scopeRow("Module", name: module.displayName, allowed: allowed)
                }
            }
            ForEach(plugins, id: \.id) { plugin in
                let allowed = authorizationManager.canUsePlugin(id: plugin.id)
                if !showOnlyBlocked || !allowed {
                    scopeRow("Plugin", name: plugin.name, allowed: allowed)
                }
            }
            ForEach(connectors, id: \.id) { connector in
                let allowed = authorizationManager.canUseConnector(id: connector.id)
                if !showOnlyBlocked || !allowed {
                    scopeRow("Connector", name: connector.name, allowed: allowed)
                }
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
}
