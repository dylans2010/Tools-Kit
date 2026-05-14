import SwiftUI

struct ScopeInspectorView: View {
    @StateObject private var authorizationManager = AuthorizationManager.shared
    @StateObject private var moduleRegistry = SDKModuleRegistry.shared
    @StateObject private var pluginManager = SDKPluginManager.shared
    @StateObject private var connectorManager = SDKConnectorManager.shared

    @State private var violations: [SDKSecurityManager.SensitiveOperation] = []

    var body: some View {
        List {
            Section("Security Health") {
                LabeledContent("Status", value: violations.isEmpty ? "Secured" : "Threats Detected")
                    .foregroundStyle(violations.isEmpty ? .green : .red)
                LabeledContent("Active Sessions", value: "\(authorizationManager.authSession != nil ? 1 : 0)")
            }

            Section("Recent Violations") {
                if violations.isEmpty {
                    Text("No security violations detected").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(violations) { violation in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(violation.scope).font(.caption.monospaced().bold())
                                Spacer()
                                Text(violation.timestamp, style: .time).font(.caption2).foregroundStyle(.secondary)
                            }
                            Text(violation.reason).font(.caption2).foregroundStyle(.red)
                        }
                    }
                }
            }

            Section("Active Scopes") {
                if authorizationManager.currentScopes().isEmpty {
                    Text("No active scopes")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(authorizationManager.currentScopes(), id: \.self) { scope in
                        Text(scope).font(.caption.monospaced())
                    }
                }
            }

            ForEach(authorizationManager.currentScopes(), id: \.self) { scope in
                Section(scope) {
                    resourceRows(for: scope)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Scope Inspector")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            violations = SDKSecurityManager.shared.sensitiveOperations
        }
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
}
